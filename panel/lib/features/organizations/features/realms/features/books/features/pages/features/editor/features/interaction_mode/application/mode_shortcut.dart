import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/interaction_mode.dart";

/// Mixin for interaction modes that provide keyboard shortcuts.
/// Provides composition-based approach for adding shortcut capabilities to modes.
mixin ModeShortcut on InteractionMode {
  /// Returns a list of keyboard shortcuts that this mode provides.
  ///
  /// These shortcuts will be automatically registered with the managed action
  /// system when this mode becomes active, and unregistered when the mode changes.
  List<ActionShortcut> getShortcuts();
}
