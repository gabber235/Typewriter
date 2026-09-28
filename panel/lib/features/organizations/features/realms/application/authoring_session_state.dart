part of "authoring_session.dart";

@freezed
abstract class AuthoringValue<T> with _$AuthoringValue<T> {
  const factory AuthoringValue({required T value, required int revision}) =
      _AuthoringValue<T>;
}

/// Canonical graph state received from Realm at one catalog generation and sequence.
@freezed
abstract class AuthoringSessionState with _$AuthoringSessionState {
  const factory AuthoringSessionState({
    skir.CatalogGeneration? generation,
    int? sequence,
    @Default({}) Map<skir.ResourceId, skir.AuthoringResource> resources,
    @Default({}) Map<skir.AuthoringEdgeId, skir.AuthoringEdge> edges,
    @Default({}) Map<skir.ResourceId, skir.PresentationSubject> presentations,
    @Default({})
    Map<skir.CompilationRoot, skir.CompiledResourceState> compiledStatuses,
    @Default({}) Map<String, skir.GraphSelectionResult> selections,
    @Default([]) List<skir.AuthoringDiagnostic> diagnostics,
    @Default(false) bool refreshing,
  }) = _AuthoringSessionState;
}

extension AuthoringGraphView on AuthoringSessionState {
  Set<skir.ResourceId> resourceIds(String selection) =>
      selections[selection]?.resourceIds.toSet() ?? const {};

  Iterable<skir.AuthoringResource> selectedResources(String selection) =>
      resourceIds(selection)
          .map((id) => resources[id])
          .whereType<skir.AuthoringResource>();

  Iterable<skir.AuthoringEdge> selectedEdges(String selection) =>
      (selections[selection]?.edgeIds ?? const [])
          .map((id) => edges[id])
          .whereType<skir.AuthoringEdge>();
}

/// Immutable state retained for one canonical graph selection.
@freezed
abstract class AuthoringSelectionLeaseState
    with _$AuthoringSelectionLeaseState {
  const factory AuthoringSelectionLeaseState({
    required skir.GraphSelection selection,
    required int retainCount,
    skir.GraphSelectionResult? result,
  }) = _AuthoringSelectionLeaseState;
}

/// A reference counted lease over one generic graph selection.
abstract interface class AuthoringSelectionLease {
  Future<void> get ready;
  void release();
}

final class _AuthoringSelectionLease implements AuthoringSelectionLease {
  _AuthoringSelectionLease(this.ready, this._release);

  @override
  final Future<void> ready;

  final void Function() _release;
  var _released = false;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}

skir.GraphSelection authoringDefinitionSelection({
  required String key,
  required Iterable<ResourceDefinitionId> definitions,
}) => skir.GraphSelection(
  key: key,
  seed: skir.ResourceSeed.createScan(
    filter: skir.ResourceFilter(
      definitions: definitions.map((definition) => definition.toWire()),
      assignableTo: null,
    ),
  ),
  steps: [],
);

extension AuthoringResourceSelection on skir.ResourceId {
  skir.GraphSelection get resourceAuthoringSelection => skir.GraphSelection(
    key: "resource:$value",
    seed: skir.ResourceSeed.createIds(
      values: [this],
      requireAssignableTo: null,
    ),
    steps: const [],
  );
}
