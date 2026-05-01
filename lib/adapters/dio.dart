/// **⚠️ DEPRECATED — This file is no longer shipped with flutter_blackbox.**
///
/// Since v0.3.0, concrete adapter implementations are generated directly into
/// your project by the CLI tool. This keeps the package dependency-free.
///
/// ## Migration
///
/// 1. Run the CLI to generate adapters:
///    ```sh
///    dart run flutter_blackbox:init --generate
///    ```
///    This creates `lib/blackbox_adapters.dart` with only the adapters your
///    project actually needs.
///
/// 2. Replace this import:
///    ```dart
///    // Before (v0.2.x)
///    import 'package:flutter_blackbox/adapters/dio.dart';
///
///    // After (v0.3.0+)
///    import 'blackbox_adapters.dart';  // generated file
///    ```
///
/// 3. Remove this import from your code — it is now a no-op.
@Deprecated(
  'Removed in v0.3.0. Run `dart run flutter_blackbox:init --generate` '
  'to generate DioBlackBoxAdapter into your project. '
  'Then import the generated `blackbox_adapters.dart` instead.',
)
library;
