import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EmptyEntryPage extends ConsumerWidget {
  const EmptyEntryPage({
    required this.pageId,
    required this.placementKind,
    super.key,
  });

  final String pageId;
  final EntryPlacementKind placementKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Pane(
      id: "empty_graph_page",
      borderRadius: context.shapes.largeBorderRadius,
      margin: EdgeInsets.only(
        top: context.spacing.space2,
        left: context.spacing.space2,
        right: context.isMobile ? context.spacing.space2 : 0,
      ),
      child: Section(
        margin: EdgeInsets.zero,
        child: EmptyScreen(
          title: "Add an entry",
          buttonText: "Add Entry",
          onPressed: () =>
              showAddEntryDialog(context, ref, pageId, placementKind),
        ),
      ),
    );
  }
}

class AddEntryButton extends ConsumerWidget {
  const AddEntryButton({
    required this.pageId,
    required this.placementKind,
    super.key,
  });

  final String pageId;
  final EntryPlacementKind placementKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton.filled(
    tooltip: "Add entry",
    onPressed: () => showAddEntryDialog(context, ref, pageId, placementKind),
    icon: const Icon(Icons.add),
  );
}

Future<void> showAddEntryDialog(
  BuildContext context,
  WidgetRef ref,
  String pageId,
  EntryPlacementKind placementKind,
) async {
  final page = await ref.read(pagesProvider(recordId("page:$pageId")).future);
  final typeState = await ref.read(pageElementTypesProvider(page.kind).future);
  switch (typeState) {
    case PageElementTypesReady():
      break;
    case PageElementTypesUnavailable(:final diagnostics):
      throw ApiException.badRequest(diagnostics.join("; "));
    case PageElementTypesLoading():
      throw ApiException.badRequest(
        "The page element catalog is still loading",
      );
  }
  final snapshot = ref.read(realmEditorCatalogProvider).value?.snapshot;
  final pageDefinition = snapshot?.pageCatalog.definitions[page.kind];
  if (snapshot == null || pageDefinition == null) {
    throw ApiException.badRequest("The page element catalog is unavailable");
  }
  final roots = switch ((pageDefinition.editor, placementKind)) {
    (RealmGraphPageEditor(:final nodeTypes), EntryPlacementKind.graph) =>
      nodeTypes,
    (
      RealmTimelinePageEditor(:final trackTypes),
      EntryPlacementKind.timelineEntry,
    ) =>
      trackTypes,
    _ => throw ApiException.badRequest(
      "The entry placement is incompatible with this page",
    ),
  };
  final allowed = {
    ...roots,
    for (final indexed in roots.indexed)
      ...?snapshot
          .subtypeResults["page:${page.kind.id}:${page.kind.revision}:${indexed.$1}"]
          ?.matches,
  };
  final definitions = ref
      .read(availableElementDefinitionsProvider)
      .where((definition) => allowed.contains(definition.rootType))
      .toList(growable: false);
  if (!context.mounted) return;
  final selected = await showDialog<ElementDefinition>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text("Add entry"),
      children: definitions.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text("No compatible entry types"),
              ),
            ]
          : [
              for (final definition in definitions)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(definition),
                  child: Text(definition.name),
                ),
            ],
    ),
  );
  if (selected == null) return;
  final ids = await ref
      .read(pageElementsProvider(pageId).notifier)
      .createEntries([selected], placementKind);
  ref
      .read(selectionProvider.notifier)
      .selectAll(ids.map(EntryIdentifier.new).toList(growable: false));
}
