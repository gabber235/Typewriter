import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class BookAuthoringNavigationAdapter
    implements AuthoringResourceNavigationAdapter {
  const BookAuthoringNavigationAdapter();

  static const _handlers = {
    "typewriter.book",
    "typewriter.page",
    "typewriter.page-element",
  };

  @override
  bool supports(String handler) => _handlers.contains(handler);

  @override
  Future<void> open(Ref ref, OpenAuthoringResourceEffect effect) async {
    final scope = AuthoringScope(
      organizationId: effect.organizationId,
      realmId: effect.realmId,
    );
    final document = ref
        .read(workingAuthoringDocumentProvider(scope))
        .requireValue;
    final ownership = document.relations.ownerPath(effect.resourceId);
    if (ownership.problem case final problem?) throw StateError(problem);
    final ownerPath = ownership.owners;
    switch (effect.navigationHandler) {
      case "typewriter.book":
        await _openBook(ref, effect, effect.resourceId);
      case "typewriter.page":
        final bookId = ownerPath.firstOrNull;
        if (bookId == null) throw StateError("The Page has no Book owner");
        await _openBook(ref, effect, bookId, pageId: effect.resourceId);
      case "typewriter.page-element":
        final pageId = ownerPath.firstOrNull;
        final bookId = ownerPath.skip(1).firstOrNull;
        if (bookId == null || pageId == null) {
          throw StateError("The element has no Page and Book owner path");
        }
        await _openBook(ref, effect, bookId, pageId: pageId);
        ref.read(selectionProvider.notifier).selectAll([
          AuthoringResourceIdentifier.inScope(scope, effect.resourceId),
        ]);
    }
  }

  Future<void> _openBook(
    Ref ref,
    OpenAuthoringResourceEffect effect,
    skir.ResourceId bookId, {
    skir.ResourceId? pageId,
  }) => ref
      .read(appRouterProvider)
      .navigate(
        BookRoute(
          organizationId: effect.organizationId.id,
          realmId: effect.realmId.id,
          bookId: bookId.id,
          children: [if (pageId != null) RouteRoute(pageId: pageId.id)],
        ),
      );
}
