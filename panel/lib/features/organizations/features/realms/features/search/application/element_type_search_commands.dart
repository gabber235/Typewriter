import "dart:ui" show Offset;

import "package:flutter/foundation.dart" show ValueListenable;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const createElementCommandId = SearchCommandId("authoring.element.create");
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

SearchCommand createElementCommand({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
}) => SearchCommand.single<ElementDefinition>(
  id: createElementCommandId,
  presentation: const SearchCommandPresentation(
    label: "Add Element",
    icon: MaterialSymbols.add_rounded,
  ),
  matcher: const SearchResultMatcher(elementTypeSearchResultType),
  execute: (execution, definition, target) async {
    if (ref.read(organizationIdProvider) != organizationId ||
        ref.read(realmIdProvider) != realmId) {
      return const SearchCommandResult.failed(
        message: "The selected realm changed while creating the element",
      );
    }

    final books = ref.read(projectedBooksProvider).value ?? const <Book>[];
    final pages = ref.read(projectedPagesProvider).value ?? const <Page>[];
    final selectedBook = resolveSearchBook(target.query, books);
    if (hasSearchSelector(target.query, authoringBookSelectorId) &&
        selectedBook == null) {
      return const SearchCommandResult.failed(
        message: "The selected book is unavailable",
      );
    }

    final currentPageId = ref.read(pageIdProvider);
    final currentPage = currentPageId == null
        ? null
        : ref.read(projectedPageProvider(currentPageId)).value;
    final preferredPage = resolveElementCreationPage(
      query: target.query,
      books: books,
      pages: pages,
      currentPage: currentPage,
    );
    if (hasSearchSelector(target.query, authoringPageSelectorId) &&
        preferredPage == null) {
      return const SearchCommandResult.failed(
        message: "The selected page is unavailable",
      );
    }
    final preferredSlot = preferredPage == null
        ? null
        : ref.read(pageCreationSlotForPageProvider(preferredPage.pageId)).value;

    skir.ResourceId? targetPageId;
    skir.ResourceId targetBookId;
    RealmAuthoringCreationSlot targetSlot;
    if (preferredPage != null &&
        preferredSlot?.acceptsRoot(definition.rootType) == true) {
      targetPageId = preferredPage.pageId;
      targetBookId = preferredPage.bookId;
      targetSlot = preferredSlot!;
    } else if (hasSearchSelector(target.query, authoringPageSelectorId)) {
      return const SearchCommandResult.failed(
        message: "The selected page is no longer compatible",
      );
    } else {
      final selection = await execution.prompts.show(
        (context) => promptElementPageSelection(
          context: context,
          initialBookId: selectedBook?.bookId ?? ref.read(bookIdProvider),
          elementDefinition: definition,
        ),
      );
      if (selection == null || !ref.mounted) {
        return const SearchCommandResult.cancelled();
      }
      targetSlot = selection.slot;
      targetPageId = selection.pageId;
      targetBookId = selection.bookId;
    }

    final livePolicy = ref
        .read(pageCreationSlotForPageProvider(targetPageId))
        .value;
    final slot = livePolicy ?? targetSlot;
    if (!slot.acceptsRoot(definition.rootType)) {
      return const SearchCommandResult.failed(
        message: "The selected page is no longer compatible",
      );
    }
    final elementId = await _createElementOnPage(
      ref: ref,
      execution: execution,
      pageId: targetPageId,
      definition: definition,
      slot: slot,
      preferredGraphAnchor: null,
    );
    if (elementId == null) return const SearchCommandResult.cancelled();
    return SearchCommandResult.completed(
      hostEffects: [
        OpenAuthoringResourceEffect(
          organizationId: organizationId,
          realmId: realmId,
          resourceId: skir.ResourceId(value: elementId),
          definition: CoreResourceDefinitionIds.element,
          bookId: targetBookId,
          ownerId: targetPageId,
          nestedIdentifier: EntryIdentifier(elementId, pageId: targetPageId.id),
        ),
      ],
    );
  },
);

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
  final placement = await ref.withReadyPageElements(
    pageId.id,
    (elements) => elements.creationPlacement(switch (slot.pagePlacement) {
      RealmPageCreationPlacement.graph => EntryPlacementKind.graph,
      RealmPageCreationPlacement.timelineTrack =>
        EntryPlacementKind.timelineEntry,
    }, preferredGraphAnchor: preferredGraphAnchor),
  );
  final page = ref.read(projectedPageProvider(pageId)).value;
  if (page == null) return null;
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
