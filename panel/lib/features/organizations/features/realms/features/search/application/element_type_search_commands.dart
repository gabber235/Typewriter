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
/// Unlike [OpenAuthoringElementEffect], this effect never navigates. Contextual
/// page search owns the executor and rejects an effect for another page.
final class SelectCreatedElementEffect implements SearchHostEffect {
  const SelectCreatedElementEffect({
    required this.pageId,
    required this.elementIdentifier,
  });

  final skir.RecordId pageId;
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
    if (hasSearchSelector(target.query, authoringBookSearchSelector) &&
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
    if (hasSearchSelector(target.query, authoringPageSearchSelector) &&
        preferredPage == null) {
      return const SearchCommandResult.failed(
        message: "The selected page is unavailable",
      );
    }
    final preferredPolicy = preferredPage == null
        ? null
        : ref
              .read(
                pageEntryCreationPolicyForPageProvider(preferredPage.pageId),
              )
              .value;

    skir.RecordId? targetPageId;
    skir.RecordId targetBookId;
    PageEntryCreationPolicy targetPolicy;
    PageCreationInput? pendingPage;
    if (preferredPage != null &&
        preferredPolicy?.accepts(definition.rootType) == true) {
      targetPageId = preferredPage.pageId;
      targetBookId = preferredPage.bookId;
      targetPolicy = preferredPolicy!;
    } else if (hasSearchSelector(target.query, authoringPageSearchSelector)) {
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
      targetPolicy = selection.policy;
      switch (selection) {
        case ExistingElementPageSelection(:final pageId, :final bookId):
          targetPageId = pageId;
          targetBookId = bookId;
        case NewElementPageSelection(:final bookId, :final input):
          targetBookId = bookId;
          pendingPage = input;
      }
    }

    final initialValue = await _prepareElementValue(
      ref: ref,
      execution: execution,
      definition: definition,
      origin: targetPageId ?? targetBookId,
    );
    if (initialValue == null || !ref.mounted) {
      return const SearchCommandResult.cancelled();
    }
    if (pendingPage case final input?) {
      final page = await ref
          .readAuthoringSession()
          .notifier
          .createPageFromInput(targetBookId, input);
      targetPageId = page.pageId;
    }

    final livePolicy = ref
        .read(pageEntryCreationPolicyForPageProvider(targetPageId!))
        .value;
    final policy = livePolicy ?? targetPolicy;
    if (!policy.accepts(definition.rootType)) {
      return const SearchCommandResult.failed(
        message: "The selected page is no longer compatible",
      );
    }
    final elementId = await _createElementOnPage(
      ref: ref,
      pageId: targetPageId,
      definition: definition,
      policy: policy,
      initialValue: initialValue,
      preferredGraphAnchor: null,
    );
    return SearchCommandResult.completed(
      hostEffects: [
        OpenAuthoringElementEffect(
          organizationId: organizationId,
          realmId: realmId,
          bookId: targetBookId,
          pageId: targetPageId,
          elementIdentifier: EntryIdentifier(
            elementId,
            pageId: targetPageId.id,
          ),
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
  required skir.RecordId pageId,
  required ValueListenable<AsyncValue<PageEntryCreationPolicy>> policy,
  Offset? preferredGraphAnchor,
}) => SearchCommand.single<ElementDefinition>(
  id: createElementOnPageCommandId,
  presentation: const SearchCommandPresentation(
    label: "Add Element",
    icon: MaterialSymbols.add_rounded,
  ),
  matcher: const SearchResultMatcher(elementTypeSearchResultType),
  dependencies: [policy],
  evaluate: (definition, target) {
    final current = policy.value;
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
    if (!current.requireValue.accepts(definition.rootType)) {
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

    final livePolicy = ref
        .read(pageEntryCreationPolicyForPageProvider(pageId))
        .value;
    if (livePolicy == null) {
      return const SearchCommandResult.failed(
        message: "Page compatibility is unavailable",
      );
    }
    if (!livePolicy.accepts(definition.rootType)) {
      return const SearchCommandResult.failed(
        message: "The selected page is no longer compatible",
      );
    }

    final initialValue = await _prepareElementValue(
      ref: ref,
      execution: execution,
      definition: definition,
      origin: pageId,
    );
    if (initialValue == null || !ref.mounted) {
      return const SearchCommandResult.cancelled();
    }
    final elementId = await _createElementOnPage(
      initialValue: initialValue,
      ref: ref,
      pageId: pageId,
      definition: definition,
      policy: livePolicy,
      preferredGraphAnchor: preferredGraphAnchor,
    );
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

Future<String> _createElementOnPage({
  required Ref ref,
  required skir.RecordId pageId,
  required ElementDefinition definition,
  required PageEntryCreationPolicy policy,
  required DataValue initialValue,
  Offset? preferredGraphAnchor,
}) async {
  final elementIds = await ref.withReadyPageElements(
    pageId.id,
    (elements) => elements.createEntries(
      [definition],
      switch (policy.placement) {
        PageEntryCreationPlacement.graph => EntryPlacementKind.graph,
        PageEntryCreationPlacement.timelineTrack =>
          EntryPlacementKind.timelineEntry,
      },
      preferredGraphAnchor: preferredGraphAnchor,
      initialValues: [initialValue],
    ),
  );
  return elementIds.single;
}

Future<DataValue?> _prepareElementValue({
  required Ref ref,
  required SearchCommandExecutionContext execution,
  required ElementDefinition definition,
  required skir.RecordId origin,
}) async {
  final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
  if (snapshot == null) {
    throw ApiException.badRequest("The editor catalog is unavailable");
  }
  final registry = TypeRegistry(
    bootstrapTypeCatalog(snapshot.catalog.definitions),
  );
  final draft = CreationDraft(
    rootType: NamedType(definition.rootType),
    registry: registry,
    fixedValues: {
      const MaterializationLocation(["field:id"]): const StringValue("pending"),
      const MaterializationLocation(["field:name"]): StringValue(
        definition.name,
      ),
    },
  );
  try {
    final initial = draft.finalize().valueOrNull;
    final value =
        initial ??
        await execution.prompts.show(
          (context) => promptElementCreationEditor(
            context: context,
            title: "Create ${definition.name}",
            draft: draft,
            presentations: snapshot.presentations.values.toList(),
            origins: [origin],
          ),
        );
    if (value == null || !ref.mounted) return null;
    if (value is! RecordValue) {
      throw ApiException.badRequest("Element values must be records");
    }
    return value;
  } finally {
    draft.dispose();
  }
}
