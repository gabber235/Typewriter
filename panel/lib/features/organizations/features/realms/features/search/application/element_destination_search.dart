import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class ElementPageSelection {
  const ElementPageSelection({
    required this.pageId,
    required this.bookId,
    required this.policy,
  });

  final skir.ResourceId pageId;
  final skir.ResourceId bookId;
  final PageEntryCreationPolicy policy;
}

SearchActivation<ElementPageSelection> elementDestinationActivation({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
  >
  compatibleKinds,
  Ref? ref,
}) => SearchActivation.custom(
  dependencies: [books, compatibleKinds],
  evaluate: (context, result) {
    final policies = compatibleKinds.value.value;
    if (policies == null) return const SearchActivationState.hidden();
    return switch (result.payload) {
      AuthoringSearchResultPayload(:final pageKind)
          when pageKind != null && policies.containsKey(pageKind) =>
        const SearchActivationState.enabled(),
      RealmPageDefinition(:final kind)
          when policies.containsKey(kind) &&
              books.value.value != null &&
              resolveSearchBook(context.query, books.value.requireValue) !=
                  null =>
        const SearchActivationState.enabled(),
      _ => const SearchActivationState.hidden(),
    };
  },
  activate: (context, result) async {
    final policies = compatibleKinds.value.value;
    if (policies == null) return const SearchActivationResult.cancelled();
    switch (result.payload) {
      case AuthoringSearchResultPayload(
        :final id,
        :final owner,
        :final pageKind,
      ):
        final policy = pageKind == null ? null : policies[pageKind];
        if (policy == null || owner == null) {
          return const SearchActivationResult.cancelled();
        }
        return SearchActivationResult.complete(
          ElementPageSelection(pageId: id, bookId: owner, policy: policy),
        );
      case RealmPageDefinition(:final kind):
        if (ref == null) return const SearchActivationResult.cancelled();
        final policy = policies[kind];
        final bookValues = books.value.value;
        final book = bookValues == null
            ? null
            : resolveSearchBook(context.query, bookValues);
        if (policy == null || book == null) {
          return const SearchActivationResult.cancelled();
        }
        final created = await context.prompts.show(
          (promptContext) => ref
              .read(resourceCreationProvider)
              .create(
                context: promptContext,
                request: ResourceCreationRequest(
                  kind: skir.ResourceKind.page,
                  title: "Create Page",
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
            policy: policy,
          ),
        );
      default:
        return const SearchActivationResult.cancelled();
    }
  },
);
