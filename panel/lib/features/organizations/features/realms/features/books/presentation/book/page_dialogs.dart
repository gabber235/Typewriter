part of "route.dart";

Future<void> createPage({
  required BuildContext context,
  required WidgetRef ref,
  String chapter = "",
}) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  await ref.createSelectedResource(
    context: context,
    definition: corePageResourceDefinition,
    creationContext: CreationContext(
      constraints: [
        CreationReferenceConstraint(
          route: [libraryPageBookEndpoint],
          target: bookId,
        ),
      ],
    ),
    supplied: (document, template) {
      if (document.resource(bookId) == null) {
        throw ApiException.badRequest("Page creation is unavailable");
      }
      final chapterValue = document.catalog.admitPortablePayloadAt(
        template.configuration,
        skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "chapter")],
        ),
        skir.DataValue.wrapStringValue(chapter),
      );
      final priorityValue = document.catalog.admitPortablePayloadAt(
        template.configuration,
        skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "priority")],
        ),
        skir.DataValue.wrapInteger("0"),
      );
      if (chapterValue == null || priorityValue == null) {
        throw ApiException.badRequest("Page creation fields are unavailable");
      }
      return [
        skir.FieldValue(name: "chapter", value: chapterValue),
        skir.FieldValue(name: "priority", value: priorityValue),
      ];
    },
  );
}
