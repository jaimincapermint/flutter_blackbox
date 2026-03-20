import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/network_request.dart';
import '../../core/network/network_response.dart';
import '../../devkit.dart';

/// A drop-in replacement for [http.Client] that reports every request
/// and response to BlackBox's network panel and honours mock rules.
///
/// ```dart
/// // Before
/// final client = http.Client();
///
/// // After — one character change
/// final client = BlackBoxHttpClient();
/// ```
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

      // Buffer response so we can log the body and still return a stream
      final bytes = await response.stream.toBytes();
      String? bodyStr;
      try {
        jsonDecode(utf8.decode(bytes));
        bodyStr = utf8.decode(bytes);
      } catch (_) {
        bodyStr = utf8.decode(bytes);
      }

      BlackBox.instance.networkStore.onResponse(NetworkResponse(
        requestId: id,
        statusCode: response.statusCode,
        durationMs: durationMs,
        headers: response.headers,
        body: bodyStr,
      ));

      // Return a new StreamedResponse with the buffered bytes
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

  // ── Helpers ───────────────────────────────────────────────────────────

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
