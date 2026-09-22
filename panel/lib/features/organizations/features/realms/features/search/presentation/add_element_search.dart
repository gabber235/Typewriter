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
    final slot = ref.valued(pageCreationSlotForPageProvider(targetPageId));

    return SearchContribution(
      session: SearchSession(
        source: ElementTypeSearchSource(
          definitions: ref.valued(availableElementDefinitionsFutureProvider),
        ),
        scope: pageCreationSlotScope(slot: slot),
        interaction: SearchInteraction(
          activation: SearchActivation.command(
            resolve: (result) => result.type == elementTypeSearchResultType
                ? createElementOnPageCommandId
                : null,
            dependencies: [slot],
          ),
          selectionMode: SearchSelectionMode.single,
          commands: [
            createElementOnPageCommand(
              ref: ref,
              organizationId: organizationId,
              realmId: realmId,
              pageId: targetPageId,
              slot: slot,
              preferredGraphAnchor: preferredGraphAnchor,
            ),
          ],
        ),
      ),
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
  rowRenderers: {
    elementTypeSearchResultType.id: buildElementTypeSearchResultItem,
  },
);
