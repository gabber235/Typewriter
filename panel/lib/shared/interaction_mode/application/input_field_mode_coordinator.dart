import "package:flutter/widgets.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/shared/interaction_mode/application/current_interaction_mode.dart";
import "package:typewriter_panel/shared/interaction_mode/application/interaction_mode.dart";
import "package:typewriter_panel/shared/interaction_mode/application/modes/insert_mode.dart";

final inputFieldModeCoordinatorProvider = Provider<InputFieldModeCoordinator>((
  ref,
) {
  final coordinator = InputFieldModeCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class InputFieldModeCoordinator {
  InputFieldModeCoordinator(this._ref) {
    FocusManager.instance.addListener(_handleFocusChanged);
    _ref.listen(currentInteractionModeProvider, (_, mode) {
      _applyMode(mode);
    });
  }

  final Ref _ref;
  final Map<String, _InputFieldRegistration> _registrations = {};
  String? _focusedInputId;

  VoidCallback register({
    required String id,
    required FocusNode inputFocusNode,
    required FocusNode surroundingFocusNode,
    VoidCallback? onInputFocus,
  }) {
    final registration = _InputFieldRegistration(
      inputFocusNode: inputFocusNode,
      surroundingFocusNode: surroundingFocusNode,
      onInputFocus: onInputFocus,
    );
    _registrations[id] = registration;
    _handleFocusChanged();

    return () {
      if (!identical(_registrations[id], registration)) return;

      _registrations.remove(id);
      if (_focusedInputId == id) {
        _focusedInputId = null;
      }

      final mode = _ref.read(currentInteractionModeProvider);
      if (mode is InsertMode && mode.id == id) {
        _ref.read(currentInteractionModeProvider.notifier).normal();
      }
    };
  }

  void begin(String id) {
    if (!_registrations.containsKey(id)) return;

    _ref.read(currentInteractionModeProvider.notifier).setMode(InsertMode(id));
  }

  void end(String id) {
    final mode = _ref.read(currentInteractionModeProvider);
    if (mode is! InsertMode || mode.id != id) return;

    _ref.read(currentInteractionModeProvider.notifier).normal();
  }

  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChanged);
    _registrations.clear();
  }

  void _handleFocusChanged() {
    final focusedEntry = _registrations.entries
        .where((entry) => entry.value.inputFocusNode.hasPrimaryFocus)
        .firstOrNull;

    if (focusedEntry == null) {
      _focusedInputId = null;
      final mode = _ref.read(currentInteractionModeProvider);
      if (mode is InsertMode && _registrations.containsKey(mode.id)) {
        _ref.read(currentInteractionModeProvider.notifier).normal();
      }
      return;
    }

    if (_focusedInputId != focusedEntry.key) {
      _focusedInputId = focusedEntry.key;
      focusedEntry.value.onInputFocus?.call();
    }

    final mode = _ref.read(currentInteractionModeProvider);
    if (mode is InsertMode && mode.id == focusedEntry.key) return;

    _ref
        .read(currentInteractionModeProvider.notifier)
        .setMode(InsertMode(focusedEntry.key));
  }

  void _applyMode(InteractionMode mode) {
    if (mode case InsertMode(:final id)) {
      final inputFocusNode = _registrations[id]?.inputFocusNode;
      if (inputFocusNode != null && !inputFocusNode.hasPrimaryFocus) {
        inputFocusNode.requestFocus();
      }
      return;
    }

    final focusedRegistration = _registrations.values.where((registration) {
      return registration.inputFocusNode.hasPrimaryFocus;
    }).firstOrNull;
    focusedRegistration?.surroundingFocusNode.requestFocus();
  }
}

final class _InputFieldRegistration {
  const _InputFieldRegistration({
    required this.inputFocusNode,
    required this.surroundingFocusNode,
    required this.onInputFocus,
  });

  final FocusNode inputFocusNode;
  final FocusNode surroundingFocusNode;
  final VoidCallback? onInputFocus;
}
