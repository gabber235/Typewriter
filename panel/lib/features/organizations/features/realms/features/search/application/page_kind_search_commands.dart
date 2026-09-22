import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const createPageCommandId = SearchCommandId("authoring.page.create");

SearchCommand createPageCommand({
  required Ref ref,
  required skir.RecordId organizationId,
  required skir.RecordId realmId,
  required ValueListenable<AsyncValue<List<Book>>> books,
}) => SearchCommand.single<RealmPageDefinition>(
  id: createPageCommandId,
  presentation: const SearchCommandPresentation(
    label: "Create Page",
    icon: MaterialSymbols.add_rounded,
  ),
  matcher: const SearchResultMatcher(pageKindSearchResultType),
  dependencies: [books],
  evaluate: (definition, target) => switch (books.value) {
    AsyncLoading() => const SearchCommandState.disabled("Loading books"),
    AsyncError() => const SearchCommandState.hidden(),
    AsyncData(:final value) =>
      resolveSearchBook(target.query, value) == null
          ? const SearchCommandState.hidden()
          : const SearchCommandState.enabled(),
  },
  execute: (execution, definition, target) async {
    final organization = ref.read(organizationIdProvider);
    final realm = ref.read(realmIdProvider);
    if (organization != organizationId || realm != realmId) {
      return const SearchCommandResult.failed(
        message: "The selected realm changed while creating the page",
      );
    }
    final book = resolveSearchBook(target.query, books.value.value ?? const []);
    if (book == null) {
      return const SearchCommandResult.failed(
        message: "Select exactly one book before creating a page",
      );
    }
    final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    final root = catalog
        ?.creationSlots[CoreAuthoringCreationSlotIds.page]
        ?.concreteRoots
        .singleOrNull;
    if (root == null) {
      return const SearchCommandResult.failed(
        message: "Page creation is unavailable",
      );
    }
    final created = await execution.prompts.show(
      (context) => ref
          .read(resourceCreationProvider)
          .create(
            context: context,
            request: ResourceCreationRequest(
              slot: CoreAuthoringCreationSlotIds.page,
              title: "Create Page",
              concreteRoot: root,
              hosts: [book.bookId],
              partial: pageCreationPartial(
                bookId: book.bookId,
                kind: definition.kind,
              ),
              referenceOrigins: [book.bookId],
            ),
          ),
    );
    if (created == null || !ref.mounted) {
      return const SearchCommandResult.cancelled();
    }
    return SearchCommandResult.completed(
      hostEffects: [
        OpenAuthoringResourceEffect(
          organizationId: organizationId,
          realmId: realmId,
          resourceId: created.id,
          definition: CoreResourceDefinitionIds.page,
          bookId: book.bookId,
          ownerId: book.bookId,
          nestedIdentifier: null,
        ),
      ],
    );
  },
);
