/// Snapshot of an outgoing HTTP request captured by a [BlackBoxHttpAdapter].
class NetworkRequest {
  const NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.timestamp,
    this.headers = const {},
    this.body,
    this.queryParameters = const {},
  });

  final String id;
  final String method;
  final String url;
  final DateTime timestamp;
  final Map<String, dynamic> headers;
  final dynamic body;
  final Map<String, String> queryParameters;

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'url': url,
        'timestamp': timestamp.toIso8601String(),
        'headers': headers,
        if (body != null) 'body': body,
        if (queryParameters.isNotEmpty) 'queryParameters': queryParameters,
      };
}
