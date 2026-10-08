import "package:typewriter_panel/typewriter_panel.dart";

part "inspection.g.dart";

/// Adapts the global selectable selection to resources supported by the
/// inspector.
///
/// [selectedProvider] remains the source of truth for identifiers and focus is
/// not consulted. A selection containing an unsupported selectable produces an
/// empty inspection rather than a partial editor.
@riverpod
AsyncValue<List<InspectableSelectable>> inspectedSelection(Ref ref) {
  final selectedAsync = ref.watch(selectedProvider);
  if (selectedAsync.mapUnready<List<InspectableSelectable>>()
      case final value?) {
    return value;
  }
  final selection = selectedAsync.requireValue;
  if (selection.any((selectable) => selectable is! InspectableSelectable)) {
    return AsyncData([]);
  }
  return AsyncData(selection.cast<InspectableSelectable>());
}

/// Whether the inspector should occupy space for the current selection.
///
/// Loading and error states intentionally remain visible. The session replaces
/// the graph with an unavailable state while selected resources refresh.
@riverpod
bool hasInspectableSelection(Ref ref) {
  return ref.watch(inspectedSelectionProvider).value?.isNotEmpty ?? true;
}

/// Owns the inspection graph and its temporary composite editor lifetime.
///
/// The provider is scoped to local work, because resource owners and drafts are
/// scoped to the same workspace session.
@riverpod
InspectionSession inspectionSession(Ref ref) {
  ref.watch(localWorkScopeProvider);
  final session = InspectionSession(ref);
  ref.onDispose(session.dispose);
  return session;
}
