import 'dart:async';

import 'mock_response.dart';
import 'network_throttle.dart';

/// A registered mock rule.
class MockRule {
  MockRule({
    required this.id,
    required this.pattern,
    required this.method,
    required this.response,
  });

  final String id;

  /// A [String] for exact URL matching or a [RegExp] for pattern matching.
  final Object pattern; // String | RegExp
  final String method; // 'GET', 'POST', '*' for any
  MockResponse response;

  bool get isEnabled => response.isEnabled;

  bool matches(String method, String url) {
    if (!isEnabled) return false;
    final methodMatch =
        this.method == '*' || this.method.toUpperCase() == method.toUpperCase();
    if (!methodMatch) return false;
    return switch (pattern) {
      String p => url.contains(p),
      RegExp r => r.hasMatch(url),
      _ => false,
    };
  }
}

/// Intercepts HTTP calls that match registered [MockRule]s and returns
/// fake responses. Rules are evaluated in registration order — first
/// match wins.
class MockEngine {
  final _rules = <MockRule>[];
  int _idCounter = 0;

  // ── Rule management ─────────────────────────────────────────────────

  List<MockRule> get rules => List.unmodifiable(_rules);

  /// Register a new mock rule. Returns the generated rule id.
  String addRule({
    required Object pattern,
    required String method,
    required MockResponse response,
  }) {
    final id = 'mock_${_idCounter++}';
    _rules.add(
        MockRule(id: id, pattern: pattern, method: method, response: response));
    return id;
  }

  void removeRule(String id) => _rules.removeWhere((r) => r.id == id);

  void toggleRule(String id) {
    final rule = _rules.cast<MockRule?>().firstWhere(
          (r) => r!.id == id,
          orElse: () => null,
        );
    if (rule != null) {
      rule.response = rule.response.copyWith(isEnabled: !rule.isEnabled);
    }
  }

  void clearRules() => _rules.clear();

  // ── Interception ────────────────────────────────────────────────────

  /// Returns the first matching [MockResponse], or null if no rule matches.
  Future<MockResponse?> intercept(String method, String url) async {
    await NetworkThrottle.instance.intercept();

    for (final rule in _rules) {
      if (rule.matches(method, url)) {
        final resp = rule.response;
        if (resp.isTimeout) {
          // Simulate timeout by waiting and then throwing
          await Future<void>.delayed(resp.delay);
          throw TimeoutException('Mock timeout for $method $url', resp.delay);
        }
        if (resp.delay > Duration.zero) {
          await Future<void>.delayed(resp.delay);
        }
        return resp;
      }
    }
    return null;
  }
}
