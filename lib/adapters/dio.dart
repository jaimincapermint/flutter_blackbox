/// Dio adapter for BlackBox.
///
/// Requires `dio: ^5.4.0` in your pubspec.yaml.
///
/// ```dart
/// import 'package:flutter_blackbox/adapters/dio.dart';
///
/// BlackBox.setup(
///   httpAdapters: [DioBlackBoxAdapter(dio)],
/// );
/// ```
library;

export 'package:flutter_blackbox/src/adapters/dio/dio_blackbox_adapter.dart';
