import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "current_interaction_mode.g.dart";

/// Riverpod notifier that manages the current active interaction mode.
///
/// This notifier provides centralized state management for the modal interface
/// system, allowing components throughout the app to:
/// - Watch the current active mode
/// - Transition between modes
/// - Access mode-specific functionality in a type-safe manner
@riverpod
class CurrentInteractionMode extends _$CurrentInteractionMode {
  @override
  InteractionMode build() => NormalMode();

  /// Transitions to a new interaction mode.
  ///
  /// Example:
  /// ```dart
  /// ref.read(currentInteractionModeProvider.notifier).setMode(MyMode());
  /// ```
  // ignore: use_setters_to_change_properties
  void setMode(InteractionMode mode) {
    state = mode;
  }

  /// Transitions to the normal interaction mode.
  void normal() {
    state = NormalMode();
  }
}
