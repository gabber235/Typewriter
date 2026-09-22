part of "route.dart";

Future<Page?> promptAndCreatePage({
  required BuildContext context,
  required WidgetRef ref,
  PageKindRef? fixedKind,
  String chapter = "",
  bool navigate = true,
}) async {
  final bookId = ref.read(bookIdProvider);
  if (bookId == null) throw ApiException.badRequest("No book selected");
  final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
  if (catalog == null) throw StateError("The editor catalog is unavailable");
  final kind =
      fixedKind ?? catalog.pageCatalog.definitions.values.firstOrNull?.kind;
  if (kind == null) {
    throw ApiException.badRequest("No page kinds are available");
  }
  final root = catalog
      .creationSlots[CoreAuthoringCreationSlotIds.page]
      ?.concreteRoots
      .singleOrNull;
  if (root == null) {
    throw ApiException.badRequest("Page creation is unavailable");
  }
  final created = await ref
      .read(resourceCreationProvider)
      .create(
        context: context,
        request: ResourceCreationRequest(
          slot: CoreAuthoringCreationSlotIds.page,
          title: "Create Page",
          concreteRoot: root,
          hosts: [bookId],
          partial: pageCreationPartial(
            bookId: bookId,
            kind: kind,
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
