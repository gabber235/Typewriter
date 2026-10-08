import "package:typewriter_panel/typewriter_panel.dart";

/// Whether the current platform is an Apple platform (macOS or iOS).
bool get isApple =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// If the user is on an Apple platform, this will return true if the [meta]
/// key is pressed. Otherwise, it will return true if the [control] key is
/// pressed.
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
