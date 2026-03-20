/// A fake HTTP response returned by the [MockEngine] instead of hitting
/// the real network.
class MockResponse {
  const MockResponse({
    this.statusCode = 200,
    this.body,
    this.headers = const {},
    this.delay = Duration.zero,
    this.isEnabled = true,
  }) : _isTimeout = false;

  const MockResponse._timeout()
      : statusCode = 0,
        body = null,
        headers = const {},
        delay = const Duration(seconds: 30),
        isEnabled = true,
        _isTimeout = true;

  /// Simulate a network timeout (throws after [delay]).
  static const MockResponse timeout = MockResponse._timeout();

  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  /// Artificial delay before the response is returned.
  final Duration delay;

  /// Toggle mocks on/off from the overlay panel without removing them.
  final bool isEnabled;

  final bool _isTimeout;
  bool get isTimeout => _isTimeout;

  MockResponse copyWith({bool? isEnabled}) => MockResponse(
        statusCode: statusCode,
        body: body,
        headers: headers,
        delay: delay,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}
