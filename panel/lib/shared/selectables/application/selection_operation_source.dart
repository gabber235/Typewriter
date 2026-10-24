import "package:typewriter_panel/typewriter_panel.dart";

/// Resolves the operations offered for a selection or for the targets of a
/// context menu.
///
/// The app installs one source above route content (AppRequiredWidgets);
/// popups reinstall the source of the context that opened them. Shared
/// selection UI asks the source and never knows which feature contributes
/// operations.
abstract interface class SelectionOperationSource {
  List<SelectionOperation> operationsFor(
    WidgetRef ref,
    List<Selectable> selection,
  );

  /// Operations for context menu [targets], or null when this source has no
  /// opinion and the caller should fall back to [operationsFor] on the current
  /// selection.
  List<SelectionOperation>? operationsForTargets(
    WidgetRef ref,
    List<SelectableIdentifier> targets,
  );
}

/// The generic operations registered for the app, filtered by what the
/// selection accepts.
final class RegisteredSelectionOperations implements SelectionOperationSource {
  const RegisteredSelectionOperations(this.operations);

  /// Operations in their declared order.
  final List<SelectionOperation> operations;

  @override
  List<SelectionOperation> operationsFor(
    WidgetRef ref,
    List<Selectable> selection,
  ) => selection.isEmpty
      ? const []
      : availableSelectionOperations(operations, selection);

  @override
  List<SelectionOperation>? operationsForTargets(
    WidgetRef ref,
    List<SelectableIdentifier> targets,
  ) => null;
}
