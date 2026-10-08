import "package:typewriter_panel/typewriter_panel.dart";

/// Provides the coordinator that synchronizes input focus with interaction mode.
///
/// The provider owns the coordinator for its Riverpod container. Disposing that
/// container removes the global focus listener and clears registrations.
final inputFieldModeCoordinatorProvider = Provider<InputFieldModeCoordinator>((
  ref,
) {
  final coordinator = InputFieldModeCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Coordinates the shared mode state for registered input fields.
///
/// Each field owns its [FocusNode]s and registers them here for as long as its
/// widget is mounted. This coordinator is the single owner of the mapping from
/// field IDs to input and surrounding focus. Focus changes and explicit begin
/// or end calls converge on the current mode. Unknown IDs and stale unregister
/// callbacks are ignored, which makes widget teardown safe when focus and
/// disposal happen in the same frame.
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
  bool _disposed = false;

  /// Registers a field and returns an idempotent unregister callback.
  ///
  /// Re registering an ID replaces its previous registration. The returned
  /// callback removes only the registration created by this call, so an older
  /// widget cannot remove a newer widget's entry. Registration also reconciles
  /// immediately with the current primary focus.
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_disposed || _registrations.containsKey(id)) return;

          final currentMode = _ref.read(currentInteractionModeProvider);
          if (currentMode is InsertMode && currentMode.id == id) {
            _ref.read(currentInteractionModeProvider.notifier).normal();
          }
        });
      }
    };
  }

  /// Enters [InsertMode] for the registered field identified by [id].
  ///
  /// The call is ignored when the field has already been disposed or was never
  /// registered. Focus reconciliation then requests the field's input focus.
  void begin(String id) {
    if (!_registrations.containsKey(id)) return;

    _ref.read(currentInteractionModeProvider.notifier).setMode(InsertMode(id));
  }

  /// Leaves insert mode when [id] still owns the active insert mode.
  ///
  /// Stale callbacks from another field cannot end a newer field's mode.
  void end(String id) {
    final mode = _ref.read(currentInteractionModeProvider);
    if (mode is! InsertMode || mode.id != id) return;

    _ref.read(currentInteractionModeProvider.notifier).normal();
  }

  /// Releases the global focus listener and all field registrations.
  void dispose() {
    _disposed = true;
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
