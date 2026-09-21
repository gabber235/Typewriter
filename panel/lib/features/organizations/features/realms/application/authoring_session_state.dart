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
    Map<skir.ResourceId, skir.CompiledResourceState> compiledStatuses,
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

@freezed
sealed class _AuthoringScope with _$AuthoringScope {
  const _AuthoringScope._();

  const factory _AuthoringScope.library() = _LibraryScope;
  const factory _AuthoringScope.book(skir.ResourceId bookId) = _BookScope;
  const factory _AuthoringScope.page(skir.ResourceId pageId) = _PageScope;

  String get key => switch (this) {
    _LibraryScope() => "library",
    _BookScope(:final bookId) => "book:${bookId.value}",
    _PageScope(:final pageId) => "page:${pageId.value}",
  };

  skir.GraphSelection get selection => switch (this) {
    _LibraryScope() => skir.GraphSelection(
      key: key,
      seed: skir.ResourceSeed.createScan(
        filter: skir.ResourceFilter(
          kinds: [skir.ResourceKind.book, skir.ResourceKind.tag],
          assignableTo: null,
        ),
      ),
      steps: const [],
    ),
    _BookScope(:final bookId) => skir.GraphSelection(
      key: key,
      seed: skir.ResourceSeed.createIds(
        values: [bookId],
        requireAssignableTo: null,
      ),
      steps: [
        skir.RelationStep(
          relations: skir.RelationFilter.any,
          direction: skir.RelationDirection.outgoing,
          minDepth: 1,
          maxDepth: 1,
          target: skir.ResourceFilter(
            kinds: [skir.ResourceKind.page],
            assignableTo: null,
          ),
        ),
      ],
    ),
    _PageScope(:final pageId) => skir.GraphSelection(
      key: key,
      seed: skir.ResourceSeed.createIds(
        values: [pageId],
        requireAssignableTo: null,
      ),
      steps: [
        skir.RelationStep(
          relations: skir.RelationFilter.any,
          direction: skir.RelationDirection.outgoing,
          minDepth: 1,
          maxDepth: 1,
          target: skir.ResourceFilter(
            kinds: [skir.ResourceKind.element],
            assignableTo: null,
          ),
        ),
        skir.RelationStep(
          relations: skir.RelationFilter.any,
          direction: skir.RelationDirection.both,
          minDepth: 1,
          maxDepth: 1,
          target: null,
        ),
      ],
    ),
  };
}

abstract interface class AuthoringScopeLease {
  Future<void> get ready;
  void release();
}

final class _AuthoringScopeLease implements AuthoringScopeLease {
  _AuthoringScopeLease(this.ready, this._release);

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
