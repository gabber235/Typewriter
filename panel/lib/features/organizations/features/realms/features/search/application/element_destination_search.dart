import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class ElementPageSelection {
  const ElementPageSelection({
    required this.pageId,
    required this.bookId,
    required this.field,
  });

  final skir.ResourceId pageId;
  final skir.ResourceId bookId;
  final RealmRelationField field;
}

SearchActivation<ElementPageSelection> elementDestinationActivation({
  required ValueListenable<AsyncValue<List<Book>>> books,
  required ValueListenable<
    AsyncValue<Map<ResolvedTypeRef, RealmRelationField>>
  >
  compatibleFields,
  Ref? ref,
}) => SearchActivation.custom(
  dependencies: [books, compatibleFields],
  evaluate: (context, result) {
    final fields = compatibleFields.value.value;
    if (fields == null) return const SearchActivationState.hidden();
    return switch (result.payload) {
      AuthoringSearchResultPayload(:final pageType)
          when pageType != null && fields.containsKey(pageType) =>
        const SearchActivationState.enabled(),
      RealmPageDefinition(:final type)
          when fields.containsKey(type) &&
              books.value.value != null &&
              resolveSearchBook(context.query, books.value.requireValue) !=
                  null =>
        const SearchActivationState.enabled(),
      _ => const SearchActivationState.hidden(),
    };
  },
  activate: (context, result) async {
    final fields = compatibleFields.value.value;
    if (fields == null) return const SearchActivationResult.cancelled();
    switch (result.payload) {
      case AuthoringSearchResultPayload(
        :final id,
        :final owner,
        :final pageType,
      ):
        final field = pageType == null ? null : fields[pageType];
        if (field == null || owner == null) {
          return const SearchActivationResult.cancelled();
        }
        return SearchActivationResult.complete(
          ElementPageSelection(pageId: id, bookId: owner, field: field),
        );
      case RealmPageDefinition(:final type):
        if (ref == null) return const SearchActivationResult.cancelled();
        final field = fields[type];
        final bookValues = books.value.value;
        final book = bookValues == null
            ? null
            : resolveSearchBook(context.query, bookValues);
        if (field == null || book == null) {
          return const SearchActivationResult.cancelled();
        }
        final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
        final bookType = catalog?.creatableRoots(CoreResourceDefinitionIds.book).singleOrNull;
        final bookField = bookType == null ? null : catalog?.relationField(
          bookType, DataPath.root.field("pages"),
        );
        if (bookField == null) return const SearchActivationResult.cancelled();
        final created = await context.prompts.show(
          (promptContext) => ref
              .read(resourceCreationProvider)
              .create(
                context: promptContext,
                request: ResourceCreationRequest(
                  definition: CoreResourceDefinitionIds.page,
                  attachment: skir.CreationAttachment(
                    host: book.bookId,
                    relation: skir.RelationId(value: bookField.relation.id),
                    hostSide: skir.RelationEndpointSide.source,
                  ),
                  title: "Create Page",
                  concreteRoot: type,
                  partial: pageCreationPartial(bookId: book.bookId),
                  referenceOrigins: [book.bookId],
                ),
              ),
        );
        if (created == null) return const SearchActivationResult.cancelled();
        return SearchActivationResult.complete(
          ElementPageSelection(
            pageId: created.id,
            bookId: book.bookId,
            field: field,
          ),
        );
      default:
        return const SearchActivationResult.cancelled();
    }
  },
);
