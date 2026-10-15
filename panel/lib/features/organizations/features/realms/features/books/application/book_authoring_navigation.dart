import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class BookAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const BookAuthoringNavigationAdapter();

  @override
  Future<void> open(Ref ref, AuthoringResourceIdentifier resource) => ref
      .read(appRouterProvider)
      .navigate(resource._bookRoute(bookId: resource.resourceId));

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) => ref
      .read(appRouterProvider)
      .navigate(
        OrganizationRoute(
          organizationId: resource.organizationId.id,
          children: [
            RealmRoute(
              realmId: resource.realmId.id,
              children: [const LibraryRoute()],
            ),
          ],
        ),
        isCurrent: isCurrent,
      );
}

final class PageAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const PageAuthoringNavigationAdapter();

  @override
  Future<void> open(Ref ref, AuthoringResourceIdentifier resource) =>
      _navigate(ref, resource);

  Future<void> _navigate(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) {
    final bookId = resource._ownerPath(ref).firstOrNull;
    if (bookId == null) throw StateError("The Page has no Book owner");
    return ref
        .read(appRouterProvider)
        .navigate(
          resource._bookRoute(bookId: bookId, pageId: resource.resourceId),
          isCurrent: isCurrent,
        );
  }

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) => _navigate(ref, resource, isCurrent: isCurrent);
}

final class PageElementAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const PageElementAuthoringNavigationAdapter();

  @override
  Future<void> open(Ref ref, AuthoringResourceIdentifier resource) async {
    await reveal(ref, resource);
    if (!ref.mounted) return;
    ref.read(selectionProvider.notifier).selectAll([resource]);
  }

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) {
    final owners = resource._ownerPath(ref);
    final pageId = owners.firstOrNull;
    final bookId = owners.skip(1).firstOrNull;
    if (bookId == null || pageId == null) {
      throw StateError("The element has no Page and Book owner path");
    }
    return ref
        .read(appRouterProvider)
        .navigate(
          resource._bookRoute(bookId: bookId, pageId: pageId),
          isCurrent: isCurrent,
        );
  }
}

extension _BookNavigation on AuthoringResourceIdentifier {
  List<skir.ResourceId> _ownerPath(Ref ref) {
    final document = ref
        .read(workingAuthoringDocumentProvider(scope))
        .requireValue;
    final ownership = document.relations.ownerPath(resourceId);
    if (ownership.problem case final problem?) throw StateError(problem);
    return ownership.owners;
  }

  BookRoute _bookRoute({
    required skir.ResourceId bookId,
    skir.ResourceId? pageId,
  }) => BookRoute(
    organizationId: this.organizationId.id,
    realmId: this.realmId.id,
    bookId: bookId.id,
    children: [if (pageId != null) RouteRoute(pageId: pageId.id)],
  );
}
