part of "route.dart";

Future<Page?> promptAndCreatePage({
  required BuildContext context,
  required WidgetRef ref,
  ResolvedTypeRef? fixedType,
  String chapter = "",
  bool navigate = true,
}) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
  if (catalog == null) throw StateError("The editor catalog is unavailable");
  final type = fixedType ?? catalog.pageCatalog.definitions.keys.firstOrNull;
  if (type == null) {
    throw ApiException.badRequest("No Page types are available");
  }
  final bookType = catalog.creatableRoots(CoreResourceDefinitionIds.book).singleOrNull;
  final field = bookType == null ? null : catalog.relationField(
    bookType,
    DataPath.root.field("pages"),
  );
  if (field == null ||
      !field.accepts(type, TypeRegistry(catalog.catalog))) {
    throw ApiException.badRequest("Page creation is unavailable");
  }
  final created = await ref
      .read(resourceCreationProvider)
      .create(
        context: context,
        request: ResourceCreationRequest(
          definition: CoreResourceDefinitionIds.page,
          title: "Create Page",
          concreteRoot: type,
          attachment: skir.CreationAttachment(
            host: bookId,
            relation: skir.RelationId(value: field.relation.id),
            hostSide: skir.RelationEndpointSide.source,
          ),
          partial: pageCreationPartial(
            bookId: bookId,
            chapter: chapter,
          ),
          referenceOrigins: [bookId],
        ),
      );
  if (created == null) return null;
  final page = Page.fromTyped(created);
  if (navigate && context.mounted) {
    unawaited(
      ref.read(appRouterProvider).push(RouteRoute(pageId: page.pageId.id)),
    );
  }
  return page;
}
