import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/library/v1/authoring.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

extension ElementCommands on AuthoringSession {
  Future<wire.ApplyAuthoringBatchResponse> createElements(
    Iterable<wire.PageElement> elements,
  ) => apply([
    for (final element in elements)
      wire.AuthoringOperation.createCreateElement(element: element),
  ]);

  Future<wire.ApplyAuthoringBatchResponse> deleteElements(
    Iterable<skir.RecordId> ids,
  ) => apply([
    for (final id in ids) wire.AuthoringOperation.createDeleteElement(id: id),
  ]);

  Future<wire.ApplyAuthoringBatchResponse> patchElement({
    required skir.RecordId id,
    wire.StringChange? name,
    List<wire.ExpectedElementValueMutation> valueMutations = const [],
  }) => apply([
    wire.AuthoringOperation.createPatchElement(
      id: id,
      page: null,
      name: name,
      placement: null,
      valueMutations: valueMutations,
    ),
  ]);

  Future<wire.ApplyAuthoringBatchResponse> changeElementPlacements(
    Iterable<(wire.PageElement, wire.ElementPlacement)> changes,
  ) => apply([
    for (final (element, placement) in changes)
      wire.AuthoringOperation.createPatchElement(
        id: element.id,
        page: null,
        name: null,
        placement: wire.ElementPlacementChange(
          expected: element.placement,
          value: placement,
        ),
        valueMutations: const [],
      ),
  ]);

  Future<wire.ApplyAuthoringBatchResponse> moveElementsToPage(
    Iterable<wire.PageElement> elements,
    skir.RecordId targetPage,
  ) => apply([
    for (final element in elements)
      wire.AuthoringOperation.createPatchElement(
        id: element.id,
        page: wire.RecordIdChange(expected: element.page, value: targetPage),
        name: null,
        placement: null,
        valueMutations: const [],
      ),
  ]);

  /// Rewrites links within the duplicated set; external targets remain unchanged.
  Future<wire.ApplyAuthoringBatchResponse> duplicateElements(
    Map<wire.PageElement, skir.RecordId> copies,
  ) {
    final rewrites = [
      for (final copy in copies.entries)
        wire.ReferenceRewrite(source: copy.key.id, target: copy.value),
    ];
    return apply([
      for (final copy in copies.entries)
        wire.AuthoringOperation.createDuplicateElement(
          sourceId: copy.key.id,
          expectedValue: copy.key.value,
          newId: copy.value,
          page: copy.key.page,
          name: "${copy.key.name} Copy",
          placement: copy.key.placement,
          referenceRewrites: rewrites,
        ),
    ]);
  }
}
