import '../../core/network/mock_response.dart';
import '../../core/network/network_request.dart';
import '../../core/network/network_response.dart';

/// Implement this interface to connect any HTTP client to BlackBox.
///
/// Companion packages (devkit_dio, devkit_http, devkit_chopper) ship
/// ready-made implementations. Custom clients can implement this
/// directly.
///
/// ## Contract
///
/// Your adapter must:
/// 1. Call [onRequest] **before** the request leaves the device.
/// 2. Check [intercept] — if non-null, return the mock instead of
///    making the real request.
/// 3. Call [onResponse] when the response arrives (or [onError] on
///    exception).
///
/// BlackBox wires the callbacks via [BlackBox.setup].
abstract class BlackBoxHttpAdapter {
  /// Unique identifier for this adapter (e.g. 'dio', 'http').
  String get name;

  // ── Callbacks set by BlackBox.setup() ─────────────────────────────────

  /// Invoked when a request is dispatched.
  void Function(NetworkRequest)? onRequestCallback;

  /// Invoked when a response is received.
  void Function(NetworkResponse)? onResponseCallback;

  // ── Adapter must call these ──────────────────────────────────────────

  void onRequest(NetworkRequest request) => onRequestCallback?.call(request);

  void onResponse(NetworkResponse response) =>
      onResponseCallback?.call(response);

  // ── Mock interception ────────────────────────────────────────────────

  /// Check if a mock rule matches this [method] + [url].
  ///
  /// Set by BlackBox — adapters call this before dispatching the real
  /// request.
  Future<MockResponse?> Function(String method, String url)? interceptCallback;

  Future<MockResponse?> intercept(String method, String url) =>
      interceptCallback?.call(method, url) ?? Future.value(null);

  /// Called by BlackBox when the adapter should be attached (e.g. add a
  /// Dio interceptor). Override to set up client-specific wiring.
  void attach() {}

  /// Called when BlackBox is disposed or the adapter is replaced.
  void detach() {}
}
