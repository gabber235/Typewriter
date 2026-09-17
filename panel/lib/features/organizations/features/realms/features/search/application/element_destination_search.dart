import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "element_destination_search.freezed.dart";

@freezed
sealed class ElementPageSelection with _$ElementPageSelection {
  const factory ElementPageSelection.existing({
    required skir.RecordId pageId,
    required skir.RecordId bookId,
    required PageEntryCreationPolicy policy,
  }) = ExistingElementPageSelection;

  const factory ElementPageSelection.create({
    required skir.RecordId bookId,
    required PageCreationInput input,
    required PageEntryCreationPolicy policy,
  }) = NewElementPageSelection;
}

SearchActivation<ElementPageSelection> elementDestinationActivation({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<PageKindRef, PageEntryCreationPolicy>>
  >
  compatibleKinds,
}) => SearchActivation.custom(
  dependencies: [books, compatibleKinds],
  evaluate: (context, result) {
    final policies = compatibleKinds.value.value;
    if (policies == null) return const SearchActivationState.hidden();
    return switch (result.payload) {
      skir.AuthoringSearchPage(:final kind)
          when policies.containsKey(PageKindRef.fromSkir(kind)) =>
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
      case skir.AuthoringSearchPage(:final id, :final kind, :final book):
        final policy = policies[PageKindRef.fromSkir(kind)];
        if (policy == null) return const SearchActivationResult.cancelled();
        return SearchActivationResult.complete(
          ElementPageSelection.existing(
            pageId: id,
            bookId: book.id,
            policy: policy,
          ),
        );
      case RealmPageDefinition(:final kind):
        final policy = policies[kind];
        final bookValues = books.value.value;
        final book = bookValues == null
            ? null
            : resolveSearchBook(context.query, bookValues);
        if (policy == null || book == null) {
          return const SearchActivationResult.cancelled();
        }
        final input = await context.prompts.show(
          (promptContext) =>
              promptPageCreation(context: promptContext, fixedKind: kind),
        );
        if (input == null) return const SearchActivationResult.cancelled();
        return SearchActivationResult.complete(
          ElementPageSelection.create(
            bookId: book.bookId,
            input: input,
            policy: policy,
          ),
        );
      default:
        return const SearchActivationResult.cancelled();
    }
  },
);
