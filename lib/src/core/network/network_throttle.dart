import 'dart:async';

class NetworkThrottle {
  NetworkThrottle._();
  static final instance = NetworkThrottle._();

  bool enabled = false;
  int delayMs = 1500;

  Future<void> intercept() async {
    if (!enabled) return;
    await Future<void>.delayed(Duration(milliseconds: delayMs));
  }
}
