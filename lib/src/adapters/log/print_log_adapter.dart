import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../core/log/log_entry.dart';
import '../../core/log/log_level.dart';
import 'devkit_log_adapter.dart';

/// Captures [debugPrint] and [developer.log] calls automatically.
///
/// Overrides [debugPrint] so every existing print statement in your
/// app is forwarded to the BlackBox log panel without any code changes.
class PrintLogAdapter extends BlackBoxLogAdapter {
  @override
  String get name => 'print';

  DebugPrintCallback? _originalDebugPrint;
  int _idCounter = 0;

  @override
  void attach() {
    _originalDebugPrint = debugPrint;

    // Override Flutter's global debugPrint
    debugPrint = (String? message, {int? wrapWidth}) {
      // Still print to console
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);

      // Forward to BlackBox
      if (message != null) {
        emitLog(LogEntry(
          id: 'log_${_idCounter++}',
          level: _inferLevel(message),
          message: message,
          timestamp: DateTime.now(),
          tag: 'print',
        ));
      }
    };
  }

  @override
  void detach() {
    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }
  }

  LogLevel _inferLevel(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') || lower.contains('exception')) {
      return LogLevel.error;
    }
    if (lower.contains('warn')) return LogLevel.warning;
    if (lower.contains('debug')) return LogLevel.debug;
    return LogLevel.info;
  }
}
