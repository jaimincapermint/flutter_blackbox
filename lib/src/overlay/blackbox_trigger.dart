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

/// Trigger using a device shake.
class ShakeTrigger extends BlackBoxTrigger {
  const ShakeTrigger({this.threshold = 15.0});

  /// Acceleration threshold in m/s² above gravity that triggers the overlay.
  final double threshold;
}

/// Trigger using a global keyboard shortcut.
class HotkeyTrigger extends BlackBoxTrigger {
  const HotkeyTrigger(
    this.key, {
    this.ctrl = false,
    this.shift = false,
  });

  /// The physical keyboard key.
  final LogicalKeyboardKey key;

  /// Whether Control/Command must be held.
  final bool ctrl;

  /// Whether Shift must be held.
  final bool shift;
}

/// Trigger using a persistent floating button on the screen.
class FloatingButtonTrigger extends BlackBoxTrigger {
  const FloatingButtonTrigger();
}

/// No automatic trigger is registered.
class NoneTrigger extends BlackBoxTrigger {
  const NoneTrigger();
}
