import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Authoring batch commands for page element lifecycle and placement changes.
///
/// Each method translates editor intent into wire operations and submits one
/// batch through [AuthoringSession]. The session remains responsible for
/// optimistic revision checks and reporting whether the batch was applied.
extension ElementCommands on AuthoringSession {
  Future<skir.ApplyAuthoringBatchResponse> applyPreviewed(
    Iterable<skir.AuthoringOperation> operations,
  ) async {
    final batch = operations.toList(growable: false);
    (await preview(batch)).requireValid();
    return apply(batch);
  }

  Future<skir.ApplyAuthoringBatchResponse> createElements(
    Iterable<skir.PageElement> elements,
  ) => apply([
    for (final element in elements)
      skir.AuthoringOperation.createCreateElement(element: element),
  ]);

  Future<skir.ApplyAuthoringBatchResponse> deleteElements(
    Iterable<skir.RecordId> ids,
  ) => apply([
    for (final id in ids) skir.AuthoringOperation.createDeleteElement(id: id),
  ]);

  Future<skir.ApplyAuthoringBatchResponse> patchElement({
    required skir.RecordId id,
    List<skir.ExpectedElementValueMutation> valueMutations = const [],
  }) => apply([
    skir.AuthoringOperation.createPatchElement(
      id: id,
      page: null,
      placement: null,
      valueMutations: valueMutations,
      elementType: null,
    ),
  ]);

  Future<skir.ApplyAuthoringBatchResponse> changeElementPlacements(
    Iterable<(skir.PageElement, skir.ElementPlacement)> changes,
  ) => apply([
    for (final (element, placement) in changes)
      skir.AuthoringOperation.createPatchElement(
        id: element.id,
        page: null,
        placement: skir.ElementPlacementChange(
          expected: element.placement,
          value: placement,
        ),
        valueMutations: const [],
        elementType: null,
      ),
  ]);

  Future<skir.ApplyAuthoringBatchResponse> replaceElementType({
    required skir.PageElement element,
    required String elementType,
    required int schemaRevision,
    required skir.TypedValue value,
  }) async {
    final operations = [
      skir.AuthoringOperation.createPatchElement(
        id: element.id,
        page: null,
        placement: null,
        valueMutations: const [],
        elementType: skir.ElementTypeChange(
          expectedElementType: element.elementType,
          expectedSchemaRevision: element.schemaRevision,
          expectedValue: element.value,
          valueElementType: elementType,
          valueSchemaRevision: schemaRevision,
          value: value,
        ),
      ),
    ];
    return applyPreviewed(operations);
  }

  /// Moves each element and its calculated placement in one guarded patch.
  Future<skir.ApplyAuthoringBatchResponse> moveElementsToPage(
    Iterable<(skir.PageElement, skir.ElementPlacement)> elements,
    skir.RecordId targetPage,
  ) async {
    final operations = [
      for (final (element, placement) in elements)
        skir.AuthoringOperation.createPatchElement(
          id: element.id,
          page: skir.RecordIdChange(expected: element.page, value: targetPage),
          placement: skir.ElementPlacementChange(
            expected: element.placement,
            value: placement,
          ),
          valueMutations: const [],
          elementType: null,
        ),
    ];
    return applyPreviewed(operations);
  }

  /// Duplicates elements and rewrites links whose targets are also duplicated.
  ///
  /// Each copy carries its already calculated placement. Links outside the
  /// copied set retain their original target.
  Future<skir.ApplyAuthoringBatchResponse> duplicateElements(
    Map<skir.PageElement, ({skir.RecordId id, skir.ElementPlacement placement})>
    copies,
  ) {
    final rewrites = [
      for (final copy in copies.entries)
        skir.ReferenceRewrite(source: copy.key.id, target: copy.value.id),
    ];
    return apply([
      for (final copy in copies.entries)
        skir.AuthoringOperation.createDuplicateElement(
          sourceId: copy.key.id,
          expectedValue: copy.key.value,
          newId: copy.value.id,
          page: copy.key.page,
          placement: copy.value.placement,
          referenceRewrites: rewrites,
          valueMutations: const [],
        ),
    ]);
  }
}

extension on skir.PreviewAuthoringBatchResponse {
  void requireValid() {
    switch (this) {
      case skir.PreviewAuthoringBatchResponse_validWrapper():
        return;
      case skir.PreviewAuthoringBatchResponse_conflictWrapper():
        throw ApiException.conflict(
          "Authoring state changed while validating the move",
        );
      case skir.PreviewAuthoringBatchResponse_invalidWrapper(:final value):
        throw ApiException.badRequest(
          value.diagnostics.map((diagnostic) => diagnostic.message).join("; "),
        );
      case skir.PreviewAuthoringBatchResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.PreviewAuthoringBatchResponse_unknown():
        throw ApiException.unknownResponseMessage();
    }
  }
}
