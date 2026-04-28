import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/network_request.dart';
import '../../core/network/network_response.dart';
import '../../blackbox.dart';
import '../http/blackbox_http_adapter.dart';

/// Connects a [Dio] instance to BlackBox's network inspector and mock engine.
///
/// Add to [BlackBox.setup]:
/// ```dart
/// final dio = Dio();
///
/// BlackBox.setup(
///   httpAdapters: [DioBlackBoxAdapter(dio)],
/// );
/// ```
///
/// After that, every request made through this [Dio] instance appears
/// in the BlackBox Network panel. Mocks registered via [BlackBox.mock] are
/// automatically honoured before the real request is dispatched.
class DioBlackBoxAdapter extends BlackBoxHttpAdapter {
  DioBlackBoxAdapter(this._dio);

  final Dio _dio;
  _BlackBoxDioInterceptor? _interceptor;

  @override
  String get name => 'dio';

  @override
  void attach() {
    _interceptor = _BlackBoxDioInterceptor(adapter: this);
    _dio.interceptors.add(_interceptor!);
  }

  @override
  void detach() {
    if (_interceptor != null) {
      _dio.interceptors.remove(_interceptor!);
      _interceptor = null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal Dio interceptor — not part of the public API
// ─────────────────────────────────────────────────────────────────────────────

class _BlackBoxDioInterceptor extends Interceptor {
  _BlackBoxDioInterceptor({required this.adapter});

  final DioBlackBoxAdapter adapter;
  int _idCounter = 0;

  // ── Request ───────────────────────────────────────────────────────────────

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final id = 'dio_${_idCounter++}_${DateTime.now().millisecondsSinceEpoch}';

    // Attach request id to extras so we can pair it with the response
    options.extra['blackbox_request_id'] = id;
    options.extra['blackbox_start_ms'] = DateTime.now().millisecondsSinceEpoch;

    // Notify BlackBox network store
    adapter.onRequest(NetworkRequest(
      id: id,
      method: options.method,
      url: '${options.baseUrl}${options.path}',
      timestamp: DateTime.now(),
      headers: _sanitiseHeaders(options.headers),
      body: _encodeBody(options.data),
      queryParameters:
          options.queryParameters.map((k, v) => MapEntry(k, v.toString())),
    ));

    // ── Mock intercept ───────────────────────────────────────────────────────
    final fullUrl = '${options.baseUrl}${options.path}';
    final mock = await adapter.intercept(options.method, fullUrl);

    if (mock != null) {
      final startMs = options.extra['blackbox_start_ms'] as int;
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;

      // Notify BlackBox that we got a (mock) response
      final mockBody = mock.body;
      final dkRes = NetworkResponse(
        requestId: id,
        statusCode: mock.statusCode,
        durationMs: durationMs,
        body: mockBody,
        headers: mock.headers,
        responseSizeBytes: _estimateSize(mockBody),
      );
      adapter.onResponse(dkRes);

      // Resolve with the mock — short-circuit the real network call
      return handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: mock.statusCode,
          data: mock.body,
          headers: Headers.fromMap(
            mock.headers.map((k, v) => MapEntry(k, [v])),
          ),
        ),
        true,
      );
    }

    // No mock matched — proceed with real request
    handler.next(options);
  }

  // ── Response ──────────────────────────────────────────────────────────────

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final body = _encodeBody(response.data);
    _recordResponse(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode ?? 0,
      headers:
          _sanitiseHeaders(Map<String, dynamic>.from(response.headers.map)),
      body: body,
      responseSizeBytes: _estimateSize(body),
    );
    handler.next(response);
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra['blackbox_request_id'] as String?;
    final startMs = err.requestOptions.extra['blackbox_start_ms'] as int?;
    if (id == null) {
      handler.next(err);
      return;
    }

    final durationMs =
        startMs != null ? DateTime.now().millisecondsSinceEpoch - startMs : 0;

    NetworkFailureType type = NetworkFailureType.connection;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      type = NetworkFailureType.timeout;
    } else if (err.type == DioExceptionType.badResponse) {
      type = NetworkFailureType.server;
    }

    final errBody = err.response?.data;
    final dkRes = NetworkResponse(
      requestId: id,
      statusCode: err.response?.statusCode ?? 0,
      headers: err.response != null
          ? _sanitiseHeaders(
              Map<String, dynamic>.from(err.response!.headers.map))
          : const {},
      body: errBody,
      durationMs: durationMs,
      failureType: type,
      responseSizeBytes: _estimateSize(errBody),
    );
    adapter.onResponse(dkRes);
    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _recordResponse({
    required RequestOptions requestOptions,
    required int statusCode,
    required Map<String, String> headers,
    dynamic body,
    int? responseSizeBytes,
  }) {
    final id = requestOptions.extra['blackbox_request_id'] as String?;
    final startMs = requestOptions.extra['blackbox_start_ms'] as int?;
    if (id == null) return;

    final durationMs =
        startMs != null ? DateTime.now().millisecondsSinceEpoch - startMs : 0;

    adapter.onResponse(NetworkResponse(
      requestId: id,
      statusCode: statusCode,
      durationMs: durationMs,
      headers: headers,
      body: body,
      responseSizeBytes: responseSizeBytes,
    ));
  }

  int? _estimateSize(dynamic body) {
    if (body == null) return null;
    try {
      if (body is String) return body.length;
      return jsonEncode(body).length;
    } catch (_) {
      return body.toString().length;
    }
  }

  Map<String, String> _sanitiseHeaders(Map<String, dynamic> raw) {
    // Remove sensitive headers from display
    const redacted = {'authorization', 'cookie', 'set-cookie', 'x-api-key'};
    return {
      for (final e in raw.entries)
        e.key: redacted.contains(e.key.toLowerCase())
            ? '*** redacted ***'
            : e.value.toString(),
    };
  }

  dynamic _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is Map || body is List) return body;
    try {
      return jsonDecode(body.toString());
    } catch (_) {
      return body.toString();
    }
  }
}
