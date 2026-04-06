import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/network_request.dart';
import '../../core/network/network_response.dart';
import '../../blackbox.dart';

/// **Deprecated.** Use `HttpBlackBoxAdapter(client)` instead.
///
/// Previously, you had to replace `http.Client()` with `BlackBoxHttpClient()`.
/// Now the adapter provides an observing wrapper client for you:
///
/// ```dart
/// // ✅ New approach — use the client provided by the adapter:
/// final adapter = HttpBlackBoxAdapter(http.Client());
/// BlackBox.setup(httpAdapters: [adapter]);
///
/// final client = adapter.client; // use this client for your API calls
///
/// // ❌ Old approach (still works, but deprecated):
/// final client = BlackBoxHttpClient();
/// ```
@Deprecated('Use HttpBlackBoxAdapter(client) and adapter.client instead')
class BlackBoxHttpClient extends http.BaseClient {
  BlackBoxHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  final http.Client _inner;
  int _idCounter = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = 'http_${_idCounter++}_${DateTime.now().millisecondsSinceEpoch}';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    final url = request.url.toString();
    final method = request.method;

    // ── Record request ────────────────────────────────────────────────
    BlackBox.instance.networkStore.onRequest(NetworkRequest(
      id: id,
      method: method,
      url: url,
      timestamp: DateTime.now(),
      headers: _sanitiseHeaders(request.headers),
      queryParameters: request.url.queryParameters,
    ));

    // ── Mock intercept ────────────────────────────────────────────────
    final mock = await BlackBox.instance.mockEngine.intercept(method, url);

    if (mock != null) {
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;
      final bodyBytes = _encodeBody(mock.body);

      BlackBox.instance.networkStore.onResponse(NetworkResponse(
        requestId: id,
        statusCode: mock.statusCode,
        durationMs: durationMs,
        headers: mock.headers,
        body: mock.body,
      ));

      return http.StreamedResponse(
        Stream.value(bodyBytes),
        mock.statusCode,
        headers: mock.headers,
        request: request,
      );
    }

    // ── Real request ──────────────────────────────────────────────────
    try {
      final response = await _inner.send(request);
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;

      final bytes = await response.stream.toBytes();
      String? bodyStr;
      try {
        bodyStr = utf8.decode(bytes);
      } catch (_) {
        bodyStr = '<binary data: ${bytes.length} bytes>';
      }

      BlackBox.instance.networkStore.onResponse(NetworkResponse(
        requestId: id,
        statusCode: response.statusCode,
        durationMs: durationMs,
        headers: response.headers,
        body: bodyStr,
      ));

      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
        request: request,
      );
    } on Exception catch (e) {
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;

      BlackBox.instance.networkStore.onResponse(NetworkResponse(
        requestId: id,
        statusCode: 0,
        headers: const {},
        durationMs: durationMs,
        failureType: NetworkFailureType.connection,
        body: e.toString(),
      ));

      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  Map<String, dynamic> _sanitiseHeaders(Map<String, String> headers) {
    const redacted = {'authorization', 'cookie', 'set-cookie', 'x-api-key'};
    return {
      for (final e in headers.entries)
        e.key: redacted.contains(e.key.toLowerCase())
            ? '*** redacted ***'
            : e.value,
    };
  }

  List<int> _encodeBody(dynamic body) {
    if (body == null) return [];
    if (body is String) return utf8.encode(body);
    return utf8.encode(jsonEncode(body));
  }
}
