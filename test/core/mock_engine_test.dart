import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blackbox/src/core/network/mock_engine.dart';
import 'package:flutter_blackbox/src/core/network/mock_response.dart';

void main() {
  group('MockEngine', () {
    late MockEngine engine;

    setUp(() => engine = MockEngine());

    test('returns null when no rules registered', () async {
      final result = await engine.intercept('GET', 'https://api.example.com');
      expect(result, isNull);
    });

    test('matches exact string pattern', () async {
      engine.addRule(
        pattern: '/api/orders',
        method: 'GET',
        response: const MockResponse(statusCode: 200, body: {'ok': true}),
      );

      final result =
          await engine.intercept('GET', 'https://api.example.com/api/orders');
      expect(result, isNotNull);
      expect(result!.statusCode, 200);
    });

    test('matches RegExp pattern', () async {
      engine.addRule(
        pattern: RegExp(r'/users/\d+'),
        method: 'GET',
        response: const MockResponse(statusCode: 200),
      );

      final match =
          await engine.intercept('GET', 'https://api.example.com/users/42');
      final noMatch =
          await engine.intercept('GET', 'https://api.example.com/users/abc');

      expect(match, isNotNull);
      expect(noMatch, isNull);
    });

    test('respects method filter', () async {
      engine.addRule(
        pattern: '/api/data',
        method: 'POST',
        response: const MockResponse(statusCode: 201),
      );

      expect(await engine.intercept('GET', 'https://api.example.com/api/data'),
          isNull);
      expect(await engine.intercept('POST', 'https://api.example.com/api/data'),
          isNotNull);
    });

    test('wildcard method matches all', () async {
      engine.addRule(
        pattern: '/health',
        method: '*',
        response: const MockResponse(statusCode: 200),
      );

      expect(await engine.intercept('GET', 'https://api.example.com/health'),
          isNotNull);
      expect(await engine.intercept('POST', 'https://api.example.com/health'),
          isNotNull);
    });

    test('disabled rule is skipped', () async {
      final id = engine.addRule(
        pattern: '/api/orders',
        method: 'GET',
        response: const MockResponse(statusCode: 200),
      );
      engine.toggleRule(id); // disable

      final result =
          await engine.intercept('GET', 'https://api.example.com/api/orders');
      expect(result, isNull);
    });

    test('toggleRule re-enables disabled rule', () async {
      final id = engine.addRule(
        pattern: '/api/orders',
        method: 'GET',
        response: const MockResponse(statusCode: 200),
      );
      engine.toggleRule(id); // disable
      engine.toggleRule(id); // re-enable

      final result =
          await engine.intercept('GET', 'https://api.example.com/api/orders');
      expect(result, isNotNull);
    });

    test('removeRule deletes it', () async {
      final id = engine.addRule(
        pattern: '/api/orders',
        method: 'GET',
        response: const MockResponse(statusCode: 200),
      );
      engine.removeRule(id);

      final result =
          await engine.intercept('GET', 'https://api.example.com/api/orders');
      expect(result, isNull);
    });

    test('first matching rule wins', () async {
      engine.addRule(
        pattern: '/api',
        method: '*',
        response: const MockResponse(statusCode: 200),
      );
      engine.addRule(
        pattern: '/api/orders',
        method: '*',
        response: const MockResponse(statusCode: 404),
      );

      final result =
          await engine.intercept('GET', 'https://api.example.com/api/orders');
      expect(result!.statusCode, 200); // first rule wins
    });

    test('respects artificial delay', () async {
      engine.addRule(
        pattern: '/slow',
        method: 'GET',
        response: const MockResponse(
            statusCode: 200, delay: Duration(milliseconds: 100)),
      );

      final start = DateTime.now();
      await engine.intercept('GET', 'https://api.example.com/slow');
      final elapsed = DateTime.now().difference(start).inMilliseconds;

      expect(elapsed, greaterThanOrEqualTo(100));
    });
  });
}
