import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// Whether the current platform is an Apple platform (macOS or iOS).
bool get isApple =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// If the user is on an Apple platform, this will return true if the [meta]
/// key is pressed. Otherwise, it will return true if the [control] key is
/// pressed.
bool get hasOverrideDown =>
    HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) &&
        !isApple ||
    HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.controlRight) &&
        !isApple ||
    HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) &&
        isApple ||
    HardwareKeyboard.instance
            .isLogicalKeyPressed(LogicalKeyboardKey.metaRight) &&
        isApple;

/// A [SingleActivator] that automatically maps the [control] key to the [meta]
/// key for Apple platforms.
///
/// On macOS and iOS, `control: true` is translated to `meta: true` so that
/// shortcuts use ⌘ instead of ^. On all other platforms, the [control] key
/// is used as-is.
class AdaptiveSingleActivator extends SingleActivator {
  AdaptiveSingleActivator(
    super.trigger, {
    bool control = false,
    super.alt,
    super.shift,
    super.includeRepeats,
  }) : super(control: control && !isApple, meta: control && isApple);

  @override
  bool operator ==(Object other) {
    if (other is! SingleActivator) return false;
    return trigger == other.trigger &&
        control == other.control &&
        meta == other.meta &&
        alt == other.alt &&
        shift == other.shift &&
        includeRepeats == other.includeRepeats;
  }

  @override
  int get hashCode =>
      Object.hash(trigger, control, meta, alt, shift, includeRepeats);
}
