import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:graphview/GraphView.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/widgets/components/app/empty_screen.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";

part "entries_graph.g.dart";

@riverpod
List<Entry> graphableEntries(Ref ref) {
  final page = ref.watch(currentPageProvider);
  if (page == null) return [];

  return page.entries.where((entry) {
    final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
    if (tags.isEmpty) {
      // Entries without a blueprint are always shown. So that the user can delete them.
      return true;
    }
    return tags.contains("trigger");
  }).toList();
}

@riverpod
List<String> graphableEntryIds(Ref ref) {
  final entries = ref.watch(graphableEntriesProvider);
  return entries.map((entry) => entry.id).toList();
}

@riverpod
bool isTriggerEntry(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return false;

  final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
  return tags.contains("trigger");
}

@riverpod
bool isTriggerableEntry(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return false;

  final tags = ref.watch(entryBlueprintTagsProvider(entry.blueprintId));
  return tags.contains("triggerable");
}

@riverpod
Set<String>? entryTriggers(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return null;

  // Check if this entry is a trigger
  if (!ref.read(isTriggerEntryProvider(entryId))) return null;

  final modifiers = ref
      .watch(modifierPathsProvider(entry.blueprintId, "entry", "triggerable"));
  return modifiers
      .expand(entry.getAll)
      .expand((value) {
        if (value is String) {
          return [value];
        }
        // The keys of a map can also be entries
        if (value is Map) {
          return value.keys.map((key) => key.toString());
        }

        return <String>[];
      })
      .where((id) => id.isNotEmpty)
      .toSet();
}

@riverpod
Graph graph(Ref ref) {
  final entries = ref.watch(graphableEntriesProvider);
  final graph = Graph();

  for (final entry in entries) {
    final node = Node.Id(entry.id);
    graph.addNode(node);
  }

  for (final entry in entries) {
    final triggeredEntryIds = ref.watch(entryTriggersProvider(entry.id));
    if (triggeredEntryIds == null) continue;

    final color = ref.watch(entryBlueprintProvider(entry.blueprintId))?.color ??
        Colors.grey;

    for (final triggeredEntryId in triggeredEntryIds) {
      if (triggeredEntryId == entry.id) continue;
      graph.addEdge(
        Node.Id(entry.id),
        Node.Id(triggeredEntryId),
        paint: Paint()..color = color,
      );
    }
  }

  return graph;
}

class EntriesGraph extends HookConsumerWidget {
  const EntriesGraph({super.key}) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryIds = ref.watch(graphableEntryIdsProvider);
    final graph = ref.watch(graphProvider);

    final builder = useMemoized(
      () => SugiyamaConfiguration()
        ..nodeSeparation = 40
        ..levelSeparation = 40
        ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT,
    );

    if (entryIds.isEmpty) {
      return EmptyScreen(
        title: "There are no graphable entries on this page.",
        buttonText: "Add Entry",
        onButtonPressed: () => ref.read(searchProvider.notifier).asBuilder()
          ..fetchNewEntry()
          ..nonGenericAddEntry()
          ..tag("trigger")
          ..open(),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width,
        vertical: MediaQuery.of(context).size.height,
      ),
      minScale: 0.0001,
      maxScale: 2.6,
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(builder),
        paint: Paint()
          ..color = Colors.green
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
        builder: (node) {
          final id = node.key?.value as String?;
          if (id == null) return const NonExistentEntry();

          final entryOnPage = entryIds.contains(id);
          if (!entryOnPage) {
            final globalEntryWithPage =
                ref.watch(globalEntryWithPageProvider(id));
            if (globalEntryWithPage == null) {
              return const NonExistentEntry();
            }

            return ExternalEntryNode(
              pageId: globalEntryWithPage.key,
              entry: globalEntryWithPage.value,
            );
          }
          return EntryNode(
            entryId: id,
            key: ValueKey(id),
          );
        },
      ),
    );
  }
}
