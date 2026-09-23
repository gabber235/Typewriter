import "dart:convert";

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension type const PageAuthoringSelectionKey(String value) {
  factory PageAuthoringSelectionKey.page(skir.ResourceId page) =>
      PageAuthoringSelectionKey("page:${page.value}");

  static PageAuthoringSelectionKey? parse(String value) =>
      value.startsWith("page:") ? PageAuthoringSelectionKey(value) : null;

  skir.ResourceId get page =>
      skir.ResourceId(value: value.substring("page:".length));
}

extension type const PageContentSelectionKey(String value) {
  factory PageContentSelectionKey.page(
    skir.ResourceId page,
    CatalogGeneration generation,
  ) => PageContentSelectionKey(
    "page-content:${base64Url.encode(utf8.encode(page.value))}:${generation.value}",
  );

  static PageContentSelectionKey? parse(String value) =>
      value.startsWith("page-content:") ? PageContentSelectionKey(value) : null;

  skir.ResourceId get page => skir.ResourceId(
    value: utf8.decode(base64Url.decode(value.split(":")[1])),
  );
}

/// Page workspace graph shapes. These remain a thin Page adapter over generic selections.
extension PageAuthoringSelections on skir.ResourceId {
  skir.GraphSelection get bookAuthoringSelection => skir.GraphSelection(
    key: "book:$value",
    seed: skir.ResourceSeed.createIds(
      values: [this],
      requireAssignableTo: null,
    ),
    steps: [
      skir.RelationStep(
        relations: skir.RelationFilter.any,
        direction: skir.RelationDirection.outgoing,
        minDepth: 1,
        maxDepth: 1,
        target: skir.ResourceFilter(
          definitions: [CoreResourceDefinitionIds.page.toWire()],
          assignableTo: null,
        ),
      ),
    ],
  );

  skir.GraphSelection get pageAuthoringSelection => skir.GraphSelection(
    key: PageAuthoringSelectionKey.page(this).value,
    seed: skir.ResourceSeed.createIds(
      values: [this],
      requireAssignableTo: null,
    ),
    steps: [
      skir.RelationStep(
        relations: skir.RelationFilter.any,
        direction: skir.RelationDirection.outgoing,
        minDepth: 1,
        maxDepth: 1,
        target: skir.ResourceFilter(
          definitions: [CoreResourceDefinitionIds.element.toWire()],
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
  );

  skir.GraphSelection pageContentSelection(RealmEditorCatalogSnapshot catalog) {
    final ownershipIds = [
      for (final relation in catalog.relations.values)
        if (relation.families.contains("resource.ownership"))
          skir.RelationId(value: relation.id),
    ]..sort((left, right) => left.value.compareTo(right.value));
    if (ownershipIds.isEmpty) {
      throw StateError("The editor catalog has no ownership relations");
    }
    return skir.GraphSelection(
      key: PageContentSelectionKey.page(this, catalog.generation).value,
      seed: skir.ResourceSeed.createIds(
        values: [this],
        requireAssignableTo: null,
      ),
      steps: [
        skir.RelationStep(
          relations: skir.RelationFilter.createDeclared(
            relationIds: ownershipIds,
          ),
          direction: skir.RelationDirection.outgoing,
          minDepth: 1,
          maxDepth: 256,
          target: skir.ResourceFilter(
            definitions: [
              CoreResourceDefinitionIds.element.toWire(),
              CoreResourceDefinitionIds.cue.toWire(),
            ],
            assignableTo: null,
          ),
        ),
        skir.RelationStep(
          relations: skir.RelationFilter.createOrdinaryReferences(
            sourcePathPrefixes: const [],
            expectedTarget: null,
          ),
          direction: skir.RelationDirection.both,
          minDepth: 1,
          maxDepth: 1,
          target: null,
        ),
      ],
    );
  }
}
