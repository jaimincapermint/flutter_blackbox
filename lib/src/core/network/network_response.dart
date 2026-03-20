/// Snapshot of an HTTP response (or error) paired with its request.
enum NetworkFailureType { none, timeout, connection, server, format }

class NetworkResponse {
  NetworkResponse({
    required this.requestId,
    this.statusCode = 0,
    required this.headers,
    this.body,
    required this.durationMs,
    this.failureType = NetworkFailureType.none,
  });

  final String requestId;
  final int statusCode;
  final Map<String, String> headers;
  final dynamic body;
  final int durationMs;
  final NetworkFailureType failureType;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'statusCode': statusCode,
        'headers': headers,
        if (body != null) 'body': body,
        'durationMs': durationMs,
        'failureType': failureType.name,
      };
}
