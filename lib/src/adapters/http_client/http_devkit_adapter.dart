import '../http/devkit_http_adapter.dart';

/// Registers dart:http (via [BlackBoxHttpClient]) with the BlackBox network
/// inspector.
///
/// After calling [BlackBox.setup] with this adapter, use [BlackBoxHttpClient]
/// instead of [http.Client] throughout your app.
///
/// ```dart
/// BlackBox.setup(
///   httpAdapters: [HttpBlackBoxAdapter()],
/// );
///
/// // Anywhere in app:
/// final client = BlackBoxHttpClient();
/// ```
class HttpBlackBoxAdapter extends BlackBoxHttpAdapter {
  @override
  String get name => 'http';

  // BlackBoxHttpClient reads callbacks directly from BlackBox.instance,
  // so no special attach wiring is needed here — the base class
  // callbacks are set by BlackBox.setup() automatically.
  @override
  void attach() {}

  @override
  void detach() {}
}
