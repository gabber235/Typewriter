import "package:typewriter_panel/typewriter_panel.dart";

/// Whether the current platform is an Apple platform (macOS or iOS).
bool get isApple =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Whether either Command key is pressed on Apple platforms, or either Control
/// key is pressed on other platforms.
bool get hasOverrideDown =>
    HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.controlLeft,
        ) &&
        !isApple ||
    HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.controlRight,
        ) &&
        !isApple ||
    HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.metaLeft,
        ) &&
        isApple ||
    HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.metaRight,
        ) &&
        isApple;

/// A [SingleActivator] that automatically maps the [control] key to the [meta]
/// key for Apple platforms.
///
/// On macOS and iOS, `control: true` is translated to `meta: true` so that
/// shortcuts use ⌘ instead of ^. On all other platforms, the [control] key
/// is used unchanged.
class AdaptiveSingleActivator extends SingleActivator {
  AdaptiveSingleActivator(
    super.trigger, {
    bool control = false,
    super.alt,
    super.shift,
    super.includeRepeats,
  }) : super(control: control && !isApple, meta: control && isApple);
}
