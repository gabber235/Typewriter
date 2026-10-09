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
    final ownerPath = effect._ownerPath(ref, effect.resourceId);
    switch (effect.navigationHandler) {
      case "typewriter.book":
        await _openBook(ref, effect, effect.resourceId);
      case "typewriter.page":
        final bookId = ownerPath.firstOrNull;
        if (bookId != null) {
          await _openBook(ref, effect, bookId, pageId: effect.resourceId);
        }
      case "typewriter.page-element":
        final pageId = ownerPath.firstOrNull;
        final bookId = ownerPath.skip(1).firstOrNull;
        if (bookId == null || pageId == null) return;
        await _openBook(ref, effect, bookId, pageId: pageId);
        ref
            .read(selectionProvider.notifier)
            .select(
              AuthoringResourceIdentifier(
                organizationId: effect.organizationId,
                realmId: effect.realmId,
                resourceId: effect.resourceId,
              ),
            );
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

extension on OpenAuthoringResourceEffect {
  List<skir.ResourceId> _ownerPath(Ref ref, skir.ResourceId start) {
    final draft = ref
        .read(
          workingAuthoringDocumentProvider(
            AuthoringScope(
              organizationId: this.organizationId,
              realmId: this.realmId,
            ),
          ),
        )
        .value;
    if (draft == null) return const [];
    final catalog = draft.catalog;
    final ownership = {
      for (final relation in catalog.snapshot.relations)
        if (relation.families.any(
          (family) => family.value == "resource.ownership",
        ))
          relation.id,
    };
    final parents = {
      for (final link in draft.links)
        if (ownership.contains(link.contract)) link.second: link.first,
    };
    final path = <skir.ResourceId>[];
    final visited = <skir.ResourceId>{start};
    var current = parents[start];
    while (current != null && visited.add(current)) {
      path.add(current);
      current = parents[current];
    }
    return path;
  }
}
