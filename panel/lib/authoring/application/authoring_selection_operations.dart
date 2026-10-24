import "package:typewriter_panel/typewriter_panel.dart";

/// Offers Realm resource operations when every selected item is an authored
/// resource of one scope, and the [generic] operations otherwise.
///
/// A selection that mixes authored resources of different scopes offers no
/// operations. Context menu targets of mixed scopes have no opinion, so the
/// caller falls back to the current selection.
final class AuthoringSelectionOperations implements SelectionOperationSource {
  const AuthoringSelectionOperations(this.generic);

  /// The source for selections that are not only authored resources.
  final SelectionOperationSource generic;

  @override
  List<SelectionOperation> operationsFor(
    WidgetRef ref,
    List<Selectable> selection,
  ) {
    if (selection.isEmpty) return const [];
    final identifiers = [for (final item in selection) item.id];
    if (identifiers.any((id) => id is! AuthoringResourceIdentifier)) {
      return generic.operationsFor(ref, selection);
    }
    final resources = identifiers.cast<AuthoringResourceIdentifier>();
    final scope = resources.first.scope;
    if (resources.any((id) => id.scope != scope)) return const [];
    return resourceSelectionOperationsFor(
      ref,
      scope,
      resources.map((id) => id.resourceId),
    );
  }

  @override
  List<SelectionOperation>? operationsForTargets(
    WidgetRef ref,
    List<SelectableIdentifier> targets,
  ) {
    if (targets.isEmpty ||
        targets.any((id) => id is! AuthoringResourceIdentifier)) {
      return null;
    }
    final resources = targets.cast<AuthoringResourceIdentifier>();
    final scope = resources.first.scope;
    if (resources.any((id) => id.scope != scope)) return null;
    return resourceSelectionOperationsFor(
      ref,
      scope,
      resources.map((id) => id.resourceId),
    );
  }
}
