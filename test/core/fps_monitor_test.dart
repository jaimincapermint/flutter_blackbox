import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blackbox/src/core/performance/fps_monitor.dart';

void main() {
  group('FpsSnapshot', () {
    test('isJanky when avgFrameMs > 16.67', () {
      const snap = FpsSnapshot(
        fps: 30,
        avgFrameMs: 33.0,
        worstFrameMs: 33.0,
        samples: [33.0],
      );
      expect(snap.isJanky, isTrue);
    });

    test('not janky at 60fps', () {
      final snap = FpsSnapshot(
        fps: 60,
        avgFrameMs: 16.0,
        worstFrameMs: 16.5,
        samples: List.filled(60, 16.0),
      );
      expect(snap.isJanky, isFalse);
    });

    test('jankyFrameCount counts frames over budget', () {
      const snap = FpsSnapshot(
        fps: 45,
        avgFrameMs: 18.0,
        worstFrameMs: 40.0,
        samples: [10.0, 20.0, 40.0, 12.0, 25.0],
      );
      // Frames > 16.67ms: 20.0, 40.0, 25.0 → count = 3
      expect(snap.jankyFrameCount, 3);
    });

    test('budgetMs is 16.67', () {
      expect(FpsSnapshot.budgetMs, closeTo(16.67, 0.01));
    });
  });

  group('FpsMonitor', () {
    test('current returns zero snapshot before start', () {
      final monitor = FpsMonitor();
      final snap = monitor.current;
      expect(snap.fps, 0);
      expect(snap.samples, isEmpty);
    });

    test('stop clears state', () {
      final monitor = FpsMonitor();
      monitor.stop();
      expect(monitor.current.samples, isEmpty);
      monitor.dispose();
    });

    test('dispose closes stream', () {
      final monitor = FpsMonitor();
      monitor.dispose();
      expect(monitor.stream.isBroadcast, isTrue);
    });
  });
}
