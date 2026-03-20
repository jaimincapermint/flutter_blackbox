import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blackbox/src/core/network/network_request.dart';
import 'package:flutter_blackbox/src/core/network/network_response.dart';
import 'package:flutter_blackbox/src/core/network/network_store.dart';

void main() {
  group('NetworkStore', () {
    late NetworkStore store;

    setUp(() => store = NetworkStore(capacity: 5));
    tearDown(() => store.dispose());

    NetworkRequest req(String id) => NetworkRequest(
          id: id,
          method: 'GET',
          url: 'https://api.example.com/$id',
          timestamp: DateTime.now(),
        );

    NetworkResponse res(String requestId, int code) => NetworkResponse(
          requestId: requestId,
          statusCode: code,
          durationMs: 120,
          headers: const {},
        );

    test('records request as pending entry', () {
      store.onRequest(req('r1'));
      expect(store.entries.length, 1);
      expect(store.entries.first.isPending, isTrue);
    });

    test('pairs response with request', () {
      store.onRequest(req('r1'));
      store.onResponse(res('r1', 200));

      expect(store.entries.first.response?.statusCode, 200);
      expect(store.entries.first.isPending, isFalse);
    });

    test('ignores response with unknown requestId', () {
      store.onRequest(req('r1'));
      store.onResponse(res('unknown', 200)); // no matching request

      expect(store.entries.first.isPending, isTrue);
    });

    test('respects capacity — drops oldest', () {
      for (var i = 0; i < 7; i++) {
        store.onRequest(req('r$i'));
      }
      expect(store.entries.length, 5);
      expect(store.entries.first.request.id, 'r2');
    });

    test('clear empties store', () {
      store.onRequest(req('r1'));
      store.clear();
      expect(store.entries, isEmpty);
    });

    test('stream emits on request and response', () async {
      final counts = <int>[];
      final sub = store.stream.listen((e) => counts.add(e.length));

      store.onRequest(req('r1'));
      store.onResponse(res('r1', 201));

      await Future<void>.delayed(Duration.zero);
      expect(counts, [1, 1]); // both emissions have 1 entry
      await sub.cancel();
    });

    test('toJson serialises both request and response', () {
      store.onRequest(req('r1'));
      store.onResponse(res('r1', 200));

      final json = store.toJson();
      expect(json.first['request']['id'], 'r1');
      expect(json.first['response']['statusCode'], 200);
    });

    test('NetworkResponse.isSuccess', () {
      expect(res('r', 200).isSuccess, isTrue);
      expect(res('r', 404).isSuccess, isFalse);
      expect(res('r', 500).isSuccess, isFalse);
    });

    test('NetworkResponse.isClientError', () {
      expect(res('r', 400).isClientError, isTrue);
      expect(res('r', 404).isClientError, isTrue);
      expect(res('r', 500).isClientError, isFalse);
    });

    test('NetworkResponse.isServerError', () {
      expect(res('r', 500).isServerError, isTrue);
      expect(res('r', 503).isServerError, isTrue);
      expect(res('r', 200).isServerError, isFalse);
    });
  });
}
