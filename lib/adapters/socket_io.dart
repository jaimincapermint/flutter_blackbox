/// Socket.IO adapter for BlackBox.
///
/// Requires `socket_io_client: ^3.0.2` in your pubspec.yaml.
///
/// ```dart
/// import 'package:flutter_blackbox/adapters/socket_io.dart';
///
/// BlackBox.setup(
///   socketAdapters: [SocketIOBlackBoxAdapter(socket)],
/// );
/// ```
library;

export 'package:flutter_blackbox/src/adapters/socket/socket_io_blackbox_adapter.dart';
