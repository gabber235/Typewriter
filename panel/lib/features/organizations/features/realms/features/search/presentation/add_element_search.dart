import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Opens the current page's element type picker.
///
/// The page identity is structural context rather than editable query text.
/// The live page policy filters results and is checked again immediately before
/// creation. Successful creation closes the modal and selects the new element.
Future<void> showAddElementSearch(
  BuildContext context, {
  required String pageId,
}) => showSearchModal<void>(
  context,
  (ref, promptContext) {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) {
      throw ApiException.badRequest("No realm selected");
    }

    final targetPageId = recordId("page:$pageId");
    final policy = ref.valued(
      pageEntryCreationPolicyForPageProvider(targetPageId),
    );

    return SearchContribution(
      session: SearchSession(
        source: ElementTypeSearchSource(
          definitions: ref.valued(availableElementDefinitionsFutureProvider),
        ),
        scope: pageElementTypeScope(policy: policy),
        interaction: SearchInteraction(
          activation: SearchActivation.command(
            resolve: (result) => result.type == elementTypeSearchResultType
                ? createElementOnPageCommandId
                : null,
            dependencies: [policy],
          ),
          selectionMode: SearchSelectionMode.single,
          commands: [
            createElementOnPageCommand(
              ref: ref,
              organizationId: organizationId,
              realmId: realmId,
              pageId: targetPageId,
              policy: policy,
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
