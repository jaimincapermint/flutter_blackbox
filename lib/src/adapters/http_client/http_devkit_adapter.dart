import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/network_request.dart';
import '../../core/network/network_response.dart';
import '../http/devkit_http_adapter.dart';

/// Adapter that silently observes all requests made through a [http.Client].
///
/// Pass your **existing** `http.Client` instance — BlackBox wraps it
/// internally without requiring any changes to your HTTP call sites.
///
/// ```dart
/// final client = http.Client(); // Your trusted code — unchanged
///
/// BlackBox.setup(
///   httpAdapters: [HttpBlackBoxAdapter(client)],
/// );
///
/// // Continue using client exactly as before:
/// final response = await client.get(Uri.parse('https://api.example.com'));
/// // ↑ BlackBox observes this automatically.
/// ```
class HttpBlackBoxAdapter extends BlackBoxHttpAdapter {
  HttpBlackBoxAdapter(this._client);

  final http.Client _client;
  int _idCounter = 0;

  @override
  String get name => 'http';

  @override
  void attach() {
    // The http package doesn't have an interceptor API like Dio.
    // The adapter intercepts via observeSend() which is called whenever
    // the developer's client makes a request through our wrapper.
  }

  /// Called by the [BlackBoxObservingClient] which wraps the original client.
  Future<http.StreamedResponse> observeSend(http.BaseRequest request) async {
    final id = 'http_${_idCounter++}_${DateTime.now().millisecondsSinceEpoch}';
    final startMs = DateTime.now().millisecondsSinceEpoch;
    final url = request.url.toString();
    final method = request.method;

    // ── Record request ──────────────────────────────────────────────────
    onRequest(NetworkRequest(
      id: id,
      method: method,
      url: url,
      timestamp: DateTime.now(),
      headers: _sanitiseHeaders(request.headers),
      queryParameters: request.url.queryParameters,
    ));

    // ── Mock intercept ──────────────────────────────────────────────────
    final mock = await intercept(method, url);

    if (mock != null) {
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;
      final bodyBytes = _encodeBody(mock.body);

      onResponse(NetworkResponse(
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

    // ── Real request (delegate to original client) ──────────────────────
    try {
      final response = await _client.send(request);
      final durationMs = DateTime.now().millisecondsSinceEpoch - startMs;

      // Buffer response so we can log the body and still return a stream
      final bytes = await response.stream.toBytes();
      String? bodyStr;
      try {
        bodyStr = utf8.decode(bytes);
      } catch (_) {
        bodyStr = '<binary data: ${bytes.length} bytes>';
      }

      onResponse(NetworkResponse(
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

      onResponse(NetworkResponse(
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
  void detach() {
    // Nothing to clean up — we don't modify the original client.
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

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
