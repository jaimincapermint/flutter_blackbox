enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error;

  String get label => switch (this) {
        LogLevel.verbose => 'VERBOSE',
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };

  /// ANSI color for terminal output (informational only).
  String get emoji => switch (this) {
        LogLevel.verbose => '⬜',
        LogLevel.debug => '🟦',
        LogLevel.info => '🟩',
        LogLevel.warning => '🟧',
        LogLevel.error => '🟥',
      };
}
