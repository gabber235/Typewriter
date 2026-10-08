import "package:typewriter_panel/typewriter_panel.dart";

part "current_interaction_mode.g.dart";

/// Owns the panel's single current interaction mode.
///
/// The provider starts in [NormalMode]. Consumers watch its state to adapt
/// focus, shortcuts, and presentation. Callers request transitions through the
/// notifier; they do not mutate a mode instance. Replacing the state is
/// synchronous, and Riverpod notifies all current watchers of the new mode.
@riverpod
class CurrentInteractionMode extends _$CurrentInteractionMode {
  @override
  InteractionMode build() => NormalMode();

  /// Makes [mode] the active mode.
  ///
  /// The mode object is retained as the new immutable state. Widgets that
  /// project mode capabilities rebuild from the resulting provider update.
  ///
  /// Example:
  /// ```dart
  /// ref.read(currentInteractionModeProvider.notifier).setMode(MyMode());
  /// ```
  // ignore: use_setters_to_change_properties
  void setMode(InteractionMode mode) {
    state = mode;
  }

  /// Returns the application to a fresh [NormalMode] instance.
  ///
  /// Use this for dismiss, cancel, and focus exit paths that should leave no
  /// mode specific state active.
  void normal() {
    state = NormalMode();
  }
}
