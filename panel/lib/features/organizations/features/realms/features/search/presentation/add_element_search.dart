import "package:flutter/widgets.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Opens the current page's element type picker.
///
/// The page identity is structural context rather than editable query text.
/// The live page policy filters results and is checked again immediately before
/// creation. Successful creation closes the modal and selects the new element.
Future<void> showAddElementSearch(
  BuildContext context, {
  required String pageId,
  Offset? preferredGraphAnchor,
}) => showSearchModal<void>(
  context,
  (ref, promptContext) {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) {
      throw ApiException.badRequest("No realm selected");
    }

    final targetPageId = skir.ResourceId(value: pageId);
    final field = ref.valued(pageElementsFieldForPageProvider(targetPageId));

    return relationSearchContribution(
      ref: ref,
      organizationId: organizationId,
      realmId: realmId,
      host: targetPageId,
      field: field,
      initialValue: (option) async {
        final page = ref.read(projectedPageProvider(targetPageId)).value;
        final editor = page == null
            ? null
            : ref
                  .read(realmEditorCatalogProvider)
                  .value
                  ?.snapshot
                  ?.pageCatalog
                  .definitions[page.rootType]
                  ?.editor;
        if (editor == null) {
          throw ApiException.badRequest("The Page editor is unavailable");
        }
        final placement = await ref.withReadyPageElements(
          pageId,
          (elements) => elements.creationPlacement(switch (editor) {
            RealmGraphPageEditor() => EntryPlacementKind.graph,
            RealmTimelinePageEditor() => EntryPlacementKind.timelineEntry,
          }, preferredGraphAnchor: preferredGraphAnchor),
        );
        return RecordValue({
          "name": StringValue(option.label),
          "placement": placementValue(placement),
        });
      },
      createdEffect: (created) => SelectCreatedElementEffect(
        pageId: targetPageId,
        elementIdentifier: EntryIdentifier(
          created.id.value,
          pageId: targetPageId.id,
        ),
      ),
    ).copyWith(
      hostEffectExecutors: [
        SearchHostEffectExecutor<SelectCreatedElementEffect>((effect) {
          if (effect.pageId != targetPageId) {
            throw StateError("Created element belongs to another page");
          }
          ref.read(selectionProvider.notifier).select(effect.elementIdentifier);
        }),
      ],
    );
  },
  searchHint: "Add element",
  rowRenderers: {...relationSearchRowRenderers},
);
