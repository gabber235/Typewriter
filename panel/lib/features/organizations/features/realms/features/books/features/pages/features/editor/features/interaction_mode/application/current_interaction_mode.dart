import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/interaction_mode.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/interaction_mode/application/modes/normal_mode.dart";

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
