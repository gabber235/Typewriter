import "package:hooks_riverpod/hooks_riverpod.dart";
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
    final handler = ref
        .read(realmEditorCatalogProvider)
        .value
        ?.snapshot
        ?.resourceDefinitions[effect.definition]
        ?.navigationHandler;
    switch (handler) {
      case "typewriter.book":
        await _openBook(ref, effect, effect.resourceId);
      case "typewriter.page":
        final bookId = effect.ownerPath.firstOrNull;
        if (bookId != null) {
          await _openBook(ref, effect, bookId, pageId: effect.resourceId);
        }
      case "typewriter.page-element":
        final pageId = effect.ownerPath.firstOrNull;
        final bookId = effect.ownerPath.skip(1).firstOrNull;
        if (bookId == null || pageId == null) return;
        await _openBook(ref, effect, bookId, pageId: pageId);
        ref
            .read(selectionProvider.notifier)
            .select(effect.elementIdentifier(ref, pageId));
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
  SelectableIdentifier elementIdentifier(Ref ref, skir.ResourceId pageId) {
    final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    final resolved = catalog == null
        ? null
        : TypeRegistry(catalog.catalog).resolveExact(rootType).valueOrNull;
    final names = {
      rootType.id,
      ...?resolved?.ancestors.map((type) => type.id),
    }.whereType<QualifiedTypeId>().map((id) => id.name).toSet();
    return names.contains("Cue")
        ? CueIdentifier(pageId: pageId.id, id: resourceId.id)
        : EntryIdentifier(resourceId.id, pageId: pageId.id);
  }
}
