import "dart:async";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart" hide ContextMenuController;
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/book.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/models/writers.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/page_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/app/writers.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "entry_node.g.dart";

@riverpod
List<String> linkablePaths(
  Ref ref,
  String entryId,
) {
  final entry = ref.read(globalEntryProvider(entryId));
  if (entry == null) return [];

  final modifiers =
      ref.read(fieldModifiersProvider(entry.blueprintId, "entry"));
  return modifiers.entries.expand((e) => entry.newPaths(e.key)).toList();
}

@riverpod
List<String> linkableDuplicatePaths(
  Ref ref,
  String entryId,
) {
  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return [];
  final tags = ref.watch(entryTagsProvider(entryId));

  final modifiers =
      ref.read(fieldModifiersProvider(entry.blueprintId, "entry"));
  return modifiers.entries
      .where((e) => tags.contains(e.value.data))
      .expand((e) => entry.newPaths(e.key))
      .toList();
}

@riverpod
List<String> _acceptingPaths(
  Ref ref,
  String entryId,
  String targetId,
) {
  final targetTags = ref.watch(entryTagsProvider(targetId));

  final entry = ref.watch(globalEntryProvider(entryId));
  if (entry == null) return [];

  final modifiers =
      ref.watch(fieldModifiersProvider(entry.blueprintId, "entry"));
  final onlyTags =
      ref.watch(fieldModifiersProvider(entry.blueprintId, "only_tags"));

  return modifiers.entries
      .where((e) {
        final onlyTagModifier = onlyTags[e.key];
        if (onlyTagModifier != null) {
          final String data = onlyTagModifier.data;
          return data.split(",").containsAny(targetTags);
        }
        return targetTags.contains(e.value.data);
      })
      .expand((e) => entry.newPaths(e.key))
      .toList();
}

class EntryNode extends HookConsumerWidget {
  const EntryNode({
    required this.entryId,
    this.contextActions = const [],
    super.key,
  }) : super();

  final String entryId;
  final List<ContextMenuTile> contextActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(inspectingEntryIdProvider.select((e) => e == entryId));
    final blueprintId = ref.watch(entryBlueprintIdProvider(entryId));
    if (blueprintId == null) return const NonExistentEntry();

    final entryName = ref.watch(entryNameProvider(entryId));
    if (entryName == null) return const NonExistentEntry();

    final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
    if (blueprint == null) return NoBlueprintEntry(entryId: entryId);

    return _EntryNode(
      id: entryId,
      type: blueprintId,
      backgroundColor: blueprint.color,
      name: entryName.formatted,
      icon: SizedBox(
        width: 18,
        child: Iconify(blueprint.icon, size: 18),
      ),
      isSelected: isSelected,
      contextActions: contextActions,
      onTap: () =>
          ref.read(inspectingEntryIdProvider.notifier).selectEntry(entryId),
    );
  }
}

@riverpod
List<Writer> _writers(Ref ref, String id) {
  final selectedEntryId = ref.watch(inspectingEntryIdProvider);

  return ref.watch(writersProvider).where((writer) {
    if (writer.entryId.isNullOrEmpty) return false;
    if (writer.entryId != id) return false;
    // If the writer has no field selected then we will always show them on the entry
    if (writer.field.isNullOrEmpty) return true;
    // Otherwise we will only show them if we are not inspecting this entry
    return selectedEntryId != id;
  }).toList();
}

Future<String?> pathSelector(
  BuildContext context,
  List<String> paths,
) async {
  if (paths.isEmpty) return null;
  if (paths.length == 1) return paths.first;

  final completer = Completer<String?>();

  ContextMenuController(
    onRemove: () async {
      // This is a hack, as the onRemove callback is called before the context tile is called.
      await Future.delayed(50.ms);
      if (completer.isCompleted) return;
      completer.complete(null);
    },
  ).showMenu(
    context: context,
    builder: (context) {
      return paths.map((path) {
        return ContextMenuTile.button(
          title: path.formatted,
          onTap: () {
            completer.complete(path);
          },
        );
      }).toList();
    },
  );

  return completer.future;
}

void moveEntryToSelectingPage(PassingRef ref, String entryId) {
  final from = ref.read(entryPageIdProvider(entryId));
  if (from == null) return;

  final blueprintId = ref.read(entryBlueprintIdProvider(entryId));
  if (blueprintId == null) return;

  final pageType = ref.read(entryBlueprintPageTypeProvider(blueprintId));

  ref.read(searchProvider.notifier).asBuilder()
    ..pageType(pageType)
    ..fetchPage(
      onSelect: (page) {
        ref.read(bookProvider.notifier).moveEntry(entryId, from, page.id);
        return true;
      },
    )
    ..fetchAddPage(
      onAdded: (page) {
        ref.read(bookProvider.notifier).moveEntry(entryId, from, page.id);
      },
    )
    ..open();
}

class _EntryNode extends HookConsumerWidget {
  const _EntryNode({
    required this.id,
    required this.type,
    this.backgroundColor = Colors.grey,
    this.name = "",
    this.icon = const Icon(Icons.book, color: Colors.white),
    this.isSelected = false,
    this.contextActions = const [],
    this.onTap,
  });
  final String id;
  final String type;
  final Color backgroundColor;
  final String name;
  final Widget icon;
  final bool isSelected;
  final List<ContextMenuTile> contextActions;

  final VoidCallback? onTap;

  Future<void> _linkWith(
    BuildContext context,
    PassingRef ref,
    List<String> paths,
  ) async {
    final page = ref.read(entryPageProvider(id));
    if (page == null) return;
    final path = await pathSelector(context, paths);
    if (path == null) return;

    page.linkWith(ref, id, path);
  }

  Future<void> _linkWithDuplicate(
    BuildContext context,
    PassingRef ref,
    List<String> paths,
  ) async {
    final page = ref.read(entryPageProvider(id));
    if (page == null) return;
    final path = await pathSelector(context, paths);
    if (path == null) return;
    await page.linkWithDuplicate(ref, id, path);
  }

  Future<void> _duplicateEntry(PassingRef ref) async {
    final page = ref.read(entryPageProvider(id));
    if (page == null) return;
    await page.duplicateEntry(ref, id);
  }

  void _deleteEntry(BuildContext context, PassingRef ref) {
    final page = ref.read(currentPageProvider);
    if (page == null) return;
    page.deleteEntryWithConfirmation(context, ref, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkablePaths = ref.watch(linkablePathsProvider(id));
    final linkableDuplicatePaths =
        ref.watch(linkableDuplicatePathsProvider(id));
    return WritersIndicator(
      provider: _writersProvider(id),
      child: LongPressDraggable(
        delay: 200.ms,
        data: EntryDrag(entryId: id),
        feedback: FakeEntryNode(entryId: id),
        childWhenDragging: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _placeholderEntry(context, ref, backgroundColor),
        ),
        child: ContextMenuRegion(
          builder: (context) {
            return [
              ...contextActions,
              if (linkablePaths.isNotEmpty)
                ContextMenuTile.button(
                  title: "Link with ...",
                  icon: TWIcons.plus,
                  onTap: () => _linkWith(context, ref.passing, linkablePaths),
                ),
              if (linkableDuplicatePaths.isNotEmpty)
                ContextMenuTile.button(
                  title: "Link with Duplicate",
                  icon: TWIcons.copy,
                  onTap: () => _linkWithDuplicate(
                    context,
                    ref.passing,
                    linkableDuplicatePaths,
                  ),
                ),
              ContextMenuTile.button(
                title: "Duplicate",
                icon: TWIcons.duplicate,
                onTap: () => _duplicateEntry(ref.passing),
              ),
              ContextMenuTile.button(
                title: "Move to ...",
                icon: TWIcons.moveEntry,
                color: Colors.blueAccent,
                onTap: () => moveEntryToSelectingPage(ref.passing, id),
              ),
              ContextMenuTile.divider(),
              ContextMenuTile.button(
                title: "Delete",
                icon: TWIcons.trash,
                color: Colors.redAccent,
                onTap: () => _deleteEntry(context, ref.passing),
              ),
            ];
          },
          child: DragTarget<EntryDrag>(
            onWillAcceptWithDetails: (details) => ref
                .read(
                  _acceptingPathsProvider(id, details.data.entryId),
                )
                .isNotEmpty,
            onAcceptWithDetails: (details) async {
              final page = ref.read(currentPageProvider);
              if (page == null) return;
              final currentEntry = ref.read(globalEntryProvider(id));
              if (currentEntry == null) return;
              final targetEntry =
                  ref.read(globalEntryProvider(details.data.entryId));
              if (targetEntry == null) return;

              final acceptedPaths =
                  ref.read(_acceptingPathsProvider(id, details.data.entryId));

              if (acceptedPaths.isEmpty) return;
              final path = await pathSelector(
                context,
                acceptedPaths,
              );
              if (path == null) return;

              await page.wireEntryToOtherEntry(
                ref.passing,
                currentEntry,
                targetEntry.id,
                path,
              );
            },
            builder: (context, candidateData, rejectedData) {
              if (rejectedData.isNotEmpty) {
                return MouseRegion(
                  cursor: SystemMouseCursors.forbidden,
                  child: Material(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: _innerEntry(context, ref, Colors.white),
                    ),
                  ),
                );
              }

              final isAccapting = candidateData.isNotEmpty;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onTap,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: AnimatedOpacity(
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                      opacity: isAccapting ? 0.5 : 1,
                      child: Material(
                        borderRadius: BorderRadius.circular(4),
                        color: backgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedContainer(
                            duration: 400.ms,
                            curve: Curves.easeOutCirc,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).scaffoldBackgroundColor
                                    : backgroundColor,
                                width: 3,
                              ),
                            ),
                            child: AnimatedSize(
                              duration: 400.ms,
                              curve: Curves.easeOutCirc,
                              alignment: Alignment.topCenter,
                              child: _innerEntry(context, ref, Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _placeholderEntry(BuildContext context, WidgetRef ref, Color color) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: DottedBorder(
        color: color,
        borderType: BorderType.RRect,
        strokeWidth: 2,
        dashPattern: const [5, 5],
        radius: const Radius.circular(1),
        padding: const EdgeInsets.all(6),
        child: _innerEntry(context, ref, color),
      ),
    );
  }

  Widget _innerEntry(BuildContext context, WidgetRef ref, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: color),
            child: icon,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontFamily: "JetBrainsMono",
              fontSize: 13,
              color: color,
              decoration: ref.watch(isEntryDeprecatedProvider(id))
                  ? TextDecoration.lineThrough
                  : null,
              decorationThickness: 2.8,
              decorationColor: Theme.of(context).scaffoldBackgroundColor,
              decorationStyle: TextDecorationStyle.wavy,
            ),
          ),
        ],
      ),
    );
  }
}

class FakeEntryNode extends HookConsumerWidget {
  const FakeEntryNode({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprintId = ref.watch(entryBlueprintIdProvider(entryId));
    if (blueprintId == null) return const NonExistentEntry();

    final name = ref.watch(entryNameProvider(entryId));
    if (name == null) return const NonExistentEntry();

    final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
    if (blueprint == null) return const NonExistentEntry();

    final isDeprecated = ref.watch(isEntryDeprecatedProvider(entryId));

    return Material(
      borderRadius: BorderRadius.circular(4),
      color: blueprint.color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Iconify(blueprint.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.formatted,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      decoration:
                          isDeprecated ? TextDecoration.lineThrough : null,
                      decorationThickness: 2.8,
                      decorationColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      decorationStyle: TextDecorationStyle.wavy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    blueprintId.formatted,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      decoration:
                          isDeprecated ? TextDecoration.lineThrough : null,
                      decorationThickness: 2.5,
                      decorationColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      decorationStyle: TextDecorationStyle.wavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoBlueprintEntry extends HookConsumerWidget {
  const NoBlueprintEntry({
    required this.entryId,
    super.key,
  });

  final String entryId;

  void _selectEntry(PassingRef ref) {
    ref.read(inspectingEntryIdProvider.notifier).selectEntry(entryId);
  }

  void _deleteEntry(BuildContext context, PassingRef ref) {
    final page = ref.read(currentPageProvider);
    if (page == null) return;
    page.deleteEntryWithConfirmation(context, ref, entryId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryName = ref.watch(entryNameProvider(entryId));
    return ContextMenuRegion(
      builder: (context) {
        return [
          ContextMenuTile.button(
            title: "Delete",
            icon: TWIcons.trash,
            color: Colors.redAccent,
            onTap: () => _deleteEntry(context, ref.passing),
          ),
        ];
      },
      child: Material(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _selectEntry(ref.passing),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entryName ?? "Non existent blueprint",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Blueprint for this entry does not exist",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NonExistentEntry extends StatelessWidget {
  const NonExistentEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Non-existent entry",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Entry reference is not an entry",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExternalEntryNode extends HookConsumerWidget {
  const ExternalEntryNode({
    required this.pageId,
    required this.entry,
    super.key,
  });

  final String pageId;
  final Entry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blueprint = ref.watch(entryBlueprintProvider(entry.blueprintId));
    final page = ref.watch(pageProvider(pageId));
    final pageName = page?.pageName.formatted ?? "Unknown page";

    if (blueprint == null) {
      return const NonExistentEntry();
    }

    final isDeprecated = ref.watch(isEntryDeprecatedProvider(entry.id));

    return LongPressDraggable(
      data: EntryDrag(entryId: entry.id),
      feedback: FakeEntryNode(entryId: entry.id),
      childWhenDragging: DottedBorder(
        color: blueprint.color,
        borderType: BorderType.RRect,
        strokeWidth: 2,
        dashPattern: const [5, 5],
        radius: const Radius.circular(1),
        child: _innerEntry(
          context,
          blueprint,
          pageName,
          blueprint.color,
          isDeprecated,
        ),
      ),
      child: ContextMenuRegion(
        builder: (context) {
          return [
            ContextMenuTile.button(
              title: "Delete Reference",
              icon: TWIcons.delete,
              color: Colors.redAccent,
              onTap: () => ref
                  .read(currentPageProvider)
                  ?.removeReferencesTo(ref.passing, entry.id),
            ),
          ];
        },
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Material(
            animationDuration: 300.ms,
            color: blueprint.color.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: blueprint.color, width: 3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => ref
                  .read(inspectingEntryIdProvider.notifier)
                  .navigateAndSelectEntry(ref.passing, entry.id),
              child: _innerEntry(
                context,
                blueprint,
                pageName,
                Colors.white,
                isDeprecated,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _innerEntry(
    BuildContext context,
    EntryBlueprint blueprint,
    String pageName,
    Color color,
    bool isDeprecated,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Iconify(blueprint.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.formattedName,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  decoration: isDeprecated ? TextDecoration.lineThrough : null,
                  decorationThickness: 2.8,
                  decorationColor: Theme.of(context).scaffoldBackgroundColor,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
              Text(
                pageName,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.open_in_new,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class EntryDrag {
  const EntryDrag({
    required this.entryId,
  });

  final String entryId;
}
