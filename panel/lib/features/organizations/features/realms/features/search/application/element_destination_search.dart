import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class ElementPageSelection {
  const ElementPageSelection({
    required this.pageId,
    required this.bookId,
    required this.slot,
  });

  final skir.ResourceId pageId;
  final skir.ResourceId bookId;
  final RealmAuthoringCreationSlot slot;
}

SearchActivation<ElementPageSelection> elementDestinationActivation({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, RealmAuthoringCreationSlot>>
  >
  compatibleKinds,
  Ref? ref,
}) => SearchActivation.custom(
  dependencies: [books, compatibleKinds],
  evaluate: (context, result) {
    final slots = compatibleKinds.value.value;
    if (slots == null) return const SearchActivationState.hidden();
    return switch (result.payload) {
      AuthoringSearchResultPayload(:final pageKind)
          when pageKind != null && slots.containsKey(pageKind) =>
        const SearchActivationState.enabled(),
      RealmPageDefinition(:final kind)
          when slots.containsKey(kind) &&
              books.value.value != null &&
              resolveSearchBook(context.query, books.value.requireValue) !=
                  null =>
        const SearchActivationState.enabled(),
      _ => const SearchActivationState.hidden(),
    };
  },
  activate: (context, result) async {
    final slots = compatibleKinds.value.value;
    if (slots == null) return const SearchActivationResult.cancelled();
    switch (result.payload) {
      case AuthoringSearchResultPayload(
        :final id,
        :final owner,
        :final pageKind,
      ):
        final slot = pageKind == null ? null : slots[pageKind];
        if (slot == null || owner == null) {
          return const SearchActivationResult.cancelled();
        }
        return SearchActivationResult.complete(
          ElementPageSelection(pageId: id, bookId: owner, slot: slot),
        );
      case RealmPageDefinition(:final kind):
        if (ref == null) return const SearchActivationResult.cancelled();
        final slot = slots[kind];
        final bookValues = books.value.value;
        final book = bookValues == null
            ? null
            : resolveSearchBook(context.query, bookValues);
        if (slot == null || book == null) {
          return const SearchActivationResult.cancelled();
        }
        final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
        final root = catalog
            ?.creationSlots[CoreAuthoringCreationSlotIds.page]
            ?.concreteRoots
            .singleOrNull;
        if (root == null) return const SearchActivationResult.cancelled();
        final created = await context.prompts.show(
          (promptContext) => ref
              .read(resourceCreationProvider)
              .create(
                context: promptContext,
                request: ResourceCreationRequest(
                  slot: CoreAuthoringCreationSlotIds.page,
                  title: "Create Page",
                  concreteRoot: root,
                  hosts: [book.bookId],
                  partial: pageCreationPartial(bookId: book.bookId, kind: kind),
                  referenceOrigins: [book.bookId],
                ),
              ),
        );
        if (created == null) return const SearchActivationResult.cancelled();
        return SearchActivationResult.complete(
          ElementPageSelection(
            pageId: created.id,
            bookId: book.bookId,
            slot: slot,
          ),
        );
      default:
        return const SearchActivationResult.cancelled();
    }
  },
);
