import "dart:async";

import "package:flutter/material.dart" hide Page;
import "package:flutter/services.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

const entrySelectionOperations = <SelectionOperation>[
  EntryDeleteOperation(),
  EntryLinkWithOperation(),
  EntryLinkWithDuplicateOperation(),
  EntryDuplicateOperation(),
  EntryMoveToPageOperation(),
  EntryReplaceWithOperation(),
];

/// Operation to create a connection between the selected entry and another entry.
class EntryLinkWithOperation extends ActivatorShortcutOperation {
  const EntryLinkWithOperation();

  @override
  String get name => "Link with...";

  @override
  String get description => "Create a connection to another entry";

  Color get color => Colors.blue;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final entries = selection.whereType<EntrySelection>().toList();
    final hasLinkablePaths = _linkablePaths(entries).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // TODO: Implement link flow:
    // 1) Use the new selector popup to pick a target entry.
    // 2) If multiple paths are possible, show the selector for a path.
    // 3) Persist the link to the backend and refresh state.
  }

  List<TypeReferenceLocation> _linkablePaths(List<EntrySelection> entries) {
    if (entries.isEmpty) return [];
    return entries
        .map(
          (entry) =>
              entry.referenceLocations().valueOrNull?.toSet() ??
              <TypeReferenceLocation>{},
        )
        .reduce((left, right) => left.intersection(right))
        .toList(growable: false);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.link),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.link),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to link with a duplicate of the selected/target entry.
class EntryLinkWithDuplicateOperation extends ActivatorShortcutOperation {
  const EntryLinkWithDuplicateOperation();

  @override
  String get name => "Link with Duplicate";

  @override
  String get description =>
      "Create a connection and duplicate the target entry";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyL, shift: true),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    if (!selection.allAre<EntrySelection>()) return false;
    final entries = selection.whereType<EntrySelection>().toList();
    final hasLinkablePaths = _linkableDuplicatePaths(entries).isNotEmpty;
    return hasLinkablePaths;
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // TODO: Implement link-with-duplicate flow:
    // 1) Pick target entry.
    // 2) Duplicate it.
    // 3) Link to the duplicate on the chosen path.
    // 4) Persist + refresh.
  }

  List<TypeReferenceLocation> _linkableDuplicatePaths(
    List<EntrySelection> entries,
  ) {
    if (entries.isEmpty) return [];
    return entries
        .map(
          (entry) =>
              entry.referenceLocations().valueOrNull?.toSet() ??
              <TypeReferenceLocation>{},
        )
        .reduce((left, right) => left.intersection(right))
        .toList(growable: false);
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.copy),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.copy),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

/// Operation to duplicate the selected entry.
class EntryDuplicateOperation extends ActivatorShortcutOperation {
  const EntryDuplicateOperation();

  @override
  String get name => "Duplicate";

  @override
  String get description => "Create a copy of this entry";

  Color get color => Colors.green;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyD),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    final cached = _cachedEntries(ref, entries);
    final pageIds = {for (final entry in cached) entry.pageId};
    if (pageIds.length != 1) {
      throw ApiException.badRequest(
        "Entries from different pages cannot be duplicated together",
      );
    }
    final duplicated = await ref.withReadyPageElements(pageIds.single, (
      elements,
    ) {
      _requireEntriesOnPage(ref, entries, pageIds.single);
      return elements.duplicateAll(
        entries.map((entry) => entry.id.id).toList(),
      );
    });
    ref
        .read(selectionProvider.notifier)
        .selectAll(duplicated.map(EntryIdentifier.new).toList());
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(Fa6Solid.clone),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(Fa6Solid.clone),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

class EntryDeleteOperation extends IntentShortcutOperation {
  const EntryDeleteOperation();

  @override
  String get name => "Delete";

  @override
  String get description => "Delete selected entries";

  @override
  Type get intent => DeleteIntent;

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      selection.allAre<EntrySelection>();

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    final entries = selected.whereType<EntrySelection>().toList();
    if (entries.isEmpty) return;
    final cached = _cachedEntries(ref, entries);
    final pageIds = {for (final entry in cached) entry.pageId};
    if (pageIds.length != 1) {
      throw ApiException.badRequest(
        "Entries from different pages cannot be deleted together",
      );
    }
    await ref.withReadyPageElements(pageIds.single, (elements) {
      _requireEntriesOnPage(ref, entries, pageIds.single);
      return elements.deleteAll(entries.map((entry) => entry.id.id).toList());
    });
    ref
        .read(selectionProvider.notifier)
        .unselectAll(entries.map((entry) => entry.id).toList());
  }

  @override
  MenuItem menuItem(WidgetRef ref) => MenuItem(
    icon: const Icon(Icons.delete),
    label: name,
    color: Theme.of(ref.context).colorScheme.error,
    onPressed: () => executeOn(ref),
  );

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) {
      final scheme = Theme.of(context).colorScheme;
      return OperationButton.filledIcon(
        operation: this,
        icon: const Icon(Icons.delete_outline, size: 16),
        label: Text(
          selection.length > 1 ? "Delete (${selection.length})" : "Delete",
        ),
        onPressed: () {
          showConfirmationDialogue(
            context: context,
            title: "Delete ${selection.length} item(s)?",
            content: "This action cannot be undone.",
            confirmText: "Delete",
            confirmColor: scheme.error,
            onConfirmColor: scheme.onError,
            onConfirm: () async => executeOn(ref),
          );
        },
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onError,
          backgroundColor: scheme.error,
        ),
      );
    },
  );
}

/// Operation to move the selected entry to another page.
class EntryMoveToPageOperation extends ActivatorShortcutOperation {
  const EntryMoveToPageOperation();

  @override
  String get name => "Move to...";

  @override
  String get description => "Move this entry to another page";

  Color get color => Colors.blueAccent;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyM),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );
    final cached = _cachedEntries(ref, entries);
    final sourcePageIds = {for (final entry in cached) entry.pageId};
    if (sourcePageIds.length != 1) {
      throw ApiException.badRequest(
        "Entries from different pages cannot be moved together",
      );
    }
    final placementKinds = {
      for (final entry in cached) entry.definition.placement.kind,
    };
    if (placementKinds.length != 1) {
      throw ApiException.badRequest(
        "Graph and timeline entries cannot be moved together",
      );
    }
    final books = await ref.read(booksProvider.future);
    final pages =
        (await Future.wait([
              for (final book in books)
                ref.read(bookPagesProvider(book.bookId, "").future),
            ]))
            .expand((values) => values)
            .where((page) {
              if (page.pageId.id == sourcePageIds.single) return false;
              final editor = ref
                  .read(realmEditorCatalogProvider)
                  .value
                  ?.snapshot
                  ?.pageCatalog
                  .definitions[page.kind]
                  ?.editor;
              return switch (placementKinds.single) {
                EntryPlacementKind.graph => editor is RealmGraphPageEditor,
                EntryPlacementKind.timelineEntry =>
                  editor is RealmTimelinePageEditor,
              };
            })
            .toList(growable: false);
    if (!ref.context.mounted) return;
    final target = await _selectTargetPage(ref.context, pages);
    if (target == null) return;
    await ref.withReadyPageElements(sourcePageIds.single, (elements) {
      _requireEntriesOnPage(ref, entries, sourcePageIds.single);
      return elements.moveEntriesToPage(
        entries.map((entry) => entry.id.id).toList(growable: false),
        target.pageId.id,
      );
    });
    ref
        .read(selectionProvider.notifier)
        .unselectAll(entries.map((entry) => entry.id).toList(growable: false));
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(HeroiconsSolid.arrow_right),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}

List<CachedPageEntry> _cachedEntries(
  WidgetRef ref,
  List<EntrySelection> entries,
) {
  final organizationId = ref.read(organizationIdProvider);
  final realmId = ref.read(realmIdProvider);
  if (organizationId == null) throw ApiException.noOrganization();
  if (realmId == null) throw ApiException.badRequest("No realm selected");
  final index = ref
      .read(realmEntryIndexProvider(organizationId, realmId))
      .requireValue;
  return [
    for (final entry in entries)
      index[entry.id.id] ?? (throw ApiException.notFound("Entry")),
  ];
}

void _requireEntriesOnPage(
  WidgetRef ref,
  List<EntrySelection> entries,
  String expectedPageId,
) {
  final current = _cachedEntries(ref, entries);
  if (current.any((entry) => entry.pageId != expectedPageId)) {
    throw ApiException.conflict("An entry moved to another page");
  }
}

Future<Page?> _selectTargetPage(BuildContext context, List<Page> pages) {
  return showDialog<Page>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text("Move to page"),
      children: pages.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text("No compatible target pages"),
              ),
            ]
          : [
              for (final page in pages)
                SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(page),
                  child: Text(page.name.formatted),
                ),
            ],
    ),
  );
}

/// Operation to replace the selected entry with another entry.
class EntryReplaceWithOperation extends ActivatorShortcutOperation {
  const EntryReplaceWithOperation();

  @override
  String get name => "Replace with...";

  @override
  String get description => "Replace this entry with another entry";

  Color get color => Colors.orange;

  @override
  List<ShortcutActivator> get activators => const [
    SingleActivator(LogicalKeyboardKey.keyR),
  ];

  @override
  bool canExecuteOn(List<Selectable> selection) {
    return selection.allAre<EntrySelection>();
  }

  @override
  FutureOr<void> executeOn(WidgetRef ref) async {
    final selected = ref.read(selectedProvider).requireValue;
    if (selected.isEmpty) return;
    // ignore: unused_local_variable
    final entries = selected.whereType<EntrySelection>().toList(
      growable: false,
    );

    // TODO: Implement replace:
    // 1) Select replacement entry (with confirmation).
    // 2) Rewire references to replacement.
    // 3) Persist and refresh.
  }

  @override
  MenuItem menuItem(WidgetRef ref) {
    return MenuItem(
      icon: const Icones(MaterialSymbols.find_replace),
      label: name,
      color: color,
      onPressed: () => executeOn(ref),
    );
  }

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => OperationButton.filledIcon(
      operation: this,
      icon: const Icones(MaterialSymbols.find_replace),
      label: Text(name),
      onPressed: () => executeOn(ref),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color),
        foregroundColor: WidgetStateProperty.all(color.on(context)),
      ),
    ),
  );
}
