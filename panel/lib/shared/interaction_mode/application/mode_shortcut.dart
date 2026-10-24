import "package:typewriter_panel/typewriter_panel.dart";

/// Adds mode specific keyboard actions to an [InteractionMode].
///
/// [GlobalModeShortcut] reads this capability from the current mode and gives
/// the shortcuts to a managed action set. The set is scoped by focus and is
/// disabled while interaction is suspended.
mixin ModeShortcut on InteractionMode {
  /// Creates the actions offered while this mode is current and active.
  ///
  /// Return fresh action values when the mode is projected. Registration and
  /// removal belong to the surrounding managed action set, not to the mode.
  List<ActionShortcut> getShortcuts();
}
