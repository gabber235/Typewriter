import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Authoring batch commands for page element lifecycle and placement changes.
///
/// Each method translates editor intent into wire operations and submits one
/// batch through [AuthoringSession]. The session remains responsible for
/// optimistic revision checks and reporting whether the batch was applied.
extension ElementCommands on AuthoringSession {
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
    skir.StringChange? name,
    List<skir.ExpectedElementValueMutation> valueMutations = const [],
  }) => apply([
    skir.AuthoringOperation.createPatchElement(
      id: id,
      page: null,
      name: name,
      placement: null,
      valueMutations: valueMutations,
    ),
  ]);

  Future<skir.ApplyAuthoringBatchResponse> changeElementPlacements(
    Iterable<(skir.PageElement, skir.ElementPlacement)> changes,
  ) => apply([
    for (final (element, placement) in changes)
      skir.AuthoringOperation.createPatchElement(
        id: element.id,
        page: null,
        name: null,
        placement: skir.ElementPlacementChange(
          expected: element.placement,
          value: placement,
        ),
        valueMutations: const [],
      ),
  ]);

  /// Moves each element and its calculated placement in one guarded patch.
  Future<skir.ApplyAuthoringBatchResponse> moveElementsToPage(
    Iterable<(skir.PageElement, skir.ElementPlacement)> elements,
    skir.RecordId targetPage,
  ) => apply([
    for (final (element, placement) in elements)
      skir.AuthoringOperation.createPatchElement(
        id: element.id,
        page: skir.RecordIdChange(expected: element.page, value: targetPage),
        name: null,
        placement: skir.ElementPlacementChange(
          expected: element.placement,
          value: placement,
        ),
        valueMutations: const [],
      ),
  ]);

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
          name: "${copy.key.name} Copy",
          placement: copy.value.placement,
          referenceRewrites: rewrites,
        ),
    ]);
  }
}
