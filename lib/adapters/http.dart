/// HTTP client adapter for BlackBox.
///
/// Requires `http: ^1.0.0` in your pubspec.yaml.
///
/// ```dart
/// import 'package:flutter_blackbox/adapters/http.dart';
///
/// final adapter = HttpBlackBoxAdapter(http.Client());
/// BlackBox.setup(
///   httpAdapters: [adapter],
/// );
/// // Use adapter.client for your HTTP calls.
/// ```
library;

export 'package:flutter_blackbox/src/adapters/http_client/http_blackbox_adapter.dart';

/// @Deprecated — Use HttpBlackBoxAdapter instead.
export 'package:flutter_blackbox/src/adapters/http_client/blackbox_http_client.dart';
