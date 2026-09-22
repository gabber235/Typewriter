import "dart:ui" show Offset;

import "package:flutter/foundation.dart" show ValueListenable;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const createElementOnPageCommandId = SearchCommandId(
  "authoring.element.create_on_page",
);

/// Requests selection of an element created on the already visible page.
///
/// Unlike [OpenAuthoringResourceEffect], this effect never navigates. Contextual
/// page search owns the executor and rejects an effect for another page.
final class SelectCreatedElementEffect implements SearchHostEffect {
  const SelectCreatedElementEffect({
    required this.pageId,
    required this.elementIdentifier,
  });

  final skir.ResourceId pageId;
  final EntryIdentifier elementIdentifier;
}

/// Creates an element on one fixed page without offering another destination.
///
/// The supplied policy controls live command availability. Execution rereads
/// the provider so a stale visible result cannot bypass changed compatibility.
SearchCommand createElementOnPageCommand({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required skir.ResourceId pageId,
  required ValueListenable<AsyncValue<RealmAuthoringCreationSlot>> slot,
  Offset? preferredGraphAnchor,
}) => SearchCommand.single<ElementDefinition>(
  id: createElementOnPageCommandId,
  presentation: const SearchCommandPresentation(
    label: "Add Element",
    icon: MaterialSymbols.add_rounded,
  ),
  matcher: const SearchResultMatcher(elementTypeSearchResultType),
  dependencies: [slot],
  evaluate: (definition, target) {
    final current = slot.value;
    if (current.isLoading) {
      return const SearchCommandState.disabled(
        "Page compatibility is still loading",
      );
    }
    if (current.hasError) {
      return const SearchCommandState.disabled(
        "Page compatibility is unavailable",
      );
    }
    if (!current.requireValue.acceptsRoot(definition.rootType)) {
      return const SearchCommandState.hidden();
    }
    return const SearchCommandState.enabled();
  },
  execute: (execution, definition, target) async {
    if (ref.read(organizationIdProvider) != organizationId ||
        ref.read(realmIdProvider) != realmId) {
      return const SearchCommandResult.failed(
        message: "The selected realm changed while creating the element",
      );
    }

    final page = ref.read(projectedPageProvider(pageId)).value;
    if (page == null) {
      return const SearchCommandResult.failed(
        message: "The selected page is unavailable",
      );
    }

    final livePolicy = ref.read(pageCreationSlotForPageProvider(pageId)).value;
    if (livePolicy == null) {
      return const SearchCommandResult.failed(
        message: "Page compatibility is unavailable",
      );
    }
    if (!livePolicy.acceptsRoot(definition.rootType)) {
      return const SearchCommandResult.failed(
        message: "The selected page is no longer compatible",
      );
    }

    final elementId = await _createElementOnPage(
      ref: ref,
      execution: execution,
      pageId: pageId,
      definition: definition,
      slot: livePolicy,
      preferredGraphAnchor: preferredGraphAnchor,
    );
    if (elementId == null) return const SearchCommandResult.cancelled();
    return SearchCommandResult.completed(
      hostEffects: [
        SelectCreatedElementEffect(
          pageId: pageId,
          elementIdentifier: EntryIdentifier(elementId, pageId: pageId.id),
        ),
      ],
    );
  },
);

Future<String?> _createElementOnPage({
  required Ref ref,
  required SearchCommandExecutionContext execution,
  required skir.ResourceId pageId,
  required ElementDefinition definition,
  required RealmAuthoringCreationSlot slot,
  Offset? preferredGraphAnchor,
}) async {
  final page = ref.read(projectedPageProvider(pageId)).value;
  if (page == null) return null;
  final pageEditor = ref
      .read(realmEditorCatalogProvider)
      .value
      ?.snapshot
      ?.pageCatalog
      .definitions[page.kind]
      ?.editor;
  if (pageEditor == null) return null;
  final placement = await ref.withReadyPageElements(
    pageId.id,
    (elements) => elements.creationPlacement(switch (pageEditor) {
      RealmGraphPageEditor() => EntryPlacementKind.graph,
      RealmTimelinePageEditor() => EntryPlacementKind.timelineEntry,
    }, preferredGraphAnchor: preferredGraphAnchor),
  );
  final created = await execution.prompts.show(
    (context) => ref
        .read(resourceCreationProvider)
        .create(
          context: context,
          request: ResourceCreationRequest(
            slot: slot.id,
            title: "Create ${definition.name}",
            concreteRoot: definition.rootType,
            hosts: [pageId],
            partial: RecordValue({
              "name": StringValue(definition.name),
              "placement": placementValue(placement),
            }),
            referenceOrigins: [pageId],
          ),
        ),
  );
  return created?.id.value;
}
