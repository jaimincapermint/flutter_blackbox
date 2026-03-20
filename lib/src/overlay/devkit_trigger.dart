import 'package:flutter/services.dart';

/// Defines how the BlackBox overlay is triggered.
sealed class BlackBoxTrigger {
  const BlackBoxTrigger();

  /// Shake the device to open (mobile). Uses accelerometer threshold.
  const factory BlackBoxTrigger.shake({double threshold}) = ShakeTrigger;

  /// Press a keyboard shortcut (desktop / web).
  const factory BlackBoxTrigger.hotkey(LogicalKeyboardKey key,
      {bool ctrl, bool shift}) = HotkeyTrigger;

  /// A small draggable floating button always visible on screen.
  const factory BlackBoxTrigger.floatingButton() = FloatingButtonTrigger;

  /// No automatic trigger — open programmatically via [BlackBox.open()].
  const factory BlackBoxTrigger.none() = NoneTrigger;
}

class ShakeTrigger extends BlackBoxTrigger {
  const ShakeTrigger({this.threshold = 15.0});
  final double threshold; // m/s² above gravity
}

class HotkeyTrigger extends BlackBoxTrigger {
  const HotkeyTrigger(
    this.key, {
    this.ctrl = false,
    this.shift = false,
  });
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool shift;
}

class FloatingButtonTrigger extends BlackBoxTrigger {
  const FloatingButtonTrigger();
}

class NoneTrigger extends BlackBoxTrigger {
  const NoneTrigger();
}
