import "package:collection/collection.dart";
import "package:collection_ext/all.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/book.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/popups.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

part "page.freezed.dart";
part "page.g.dart";

@riverpod
List<Page> pages(Ref ref) {
  return ref.watch(bookProvider).pages;
}

@riverpod
Page? page(Ref ref, String pageId) {
  return ref.watch(pagesProvider).firstWhereOrNull((page) => page.id == pageId);
}

@riverpod
String? pageName(Ref ref, String pageId) {
  return ref.watch(pageProvider(pageId))?.pageName;
}

@riverpod
bool pageExists(Ref ref, String pageId) {
  return ref.watch(pageProvider(pageId)) != null;
}

@riverpod
PageType pageType(Ref ref, String pageId) {
  return ref.watch(pageProvider(pageId))?.type ?? PageType.sequence;
}

@riverpod
String pageChapter(Ref ref, String pageId) {
  return ref.watch(pageProvider(pageId))?.chapter ?? "";
}

@riverpod
int pagePriority(Ref ref, String pageId) {
  return ref.watch(pageProvider(pageId))?.priority ?? 0;
}

@riverpod
String? entryPageId(Ref ref, String entryId) {
  return ref
      .watch(pagesProvider)
      .firstWhereOrNull(
        (page) => page.entries.any((entry) => entry.id == entryId),
      )
      ?.id;
}

@riverpod
Page? entryPage(Ref ref, String entryId) {
  return ref.watch(pagesProvider).firstWhereOrNull(
        (page) => page.entries.any((entry) => entry.id == entryId),
      );
}

@riverpod
Entry? entry(Ref ref, String pageId, String entryId) {
  return ref
      .watch(pageProvider(pageId))
      ?.entries
      .firstWhereOrNull((entry) => entry.id == entryId);
}

@riverpod
Entry? globalEntry(Ref ref, String entryId) {
  final pages = ref.watch(pagesProvider);
  for (final page in pages) {
    final entry = page.entries.firstWhereOrNull((entry) => entry.id == entryId);
    if (entry != null) {
      return entry;
    }
  }
  return null;
}

@riverpod
MapEntry<String, Entry>? globalEntryWithPage(
  Ref ref,
  String entryId,
) {
  final pageId = ref.watch(entryPageIdProvider(entryId));
  if (pageId == null) {
    return null;
  }
  final entry = ref.watch(entryProvider(pageId, entryId));
  if (entry == null) {
    return null;
  }
  return MapEntry(pageId, entry);
}

@riverpod
bool entryExists(Ref ref, String entryId) {
  return ref.watch(entryPageIdProvider(entryId)) != null;
}

enum PageType {
  sequence("trigger", ["triggerable"], TWIcons.projectDiagram, Colors.blue),
  static("static", [], TWIcons.pin, Colors.deepPurple),
  cinematic("cinematic", [], TWIcons.film, Colors.orange),
  manifest(
    "manifest",
    ["manifest", "audience"],
    TWIcons.treeGraph,
    Colors.green,
  ),
  ;

  const PageType(this.tag, this.linkingTags, this.icon, this.color);

  final String tag;
  final List<String> linkingTags;
  final String icon;
  final Color color;

  static PageType fromBlueprint(EntryBlueprint blueprint) {
    final pageType =
        values.firstWhereOrNull((type) => blueprint.tags.contains(type.tag));
    if (pageType == null) {
      throw Exception(
        "No page type found for blueprint ${blueprint.name}, make sure it has one of the following tags: ${values.map((type) => type.tag).join(", ")}",
      );
    }
    return pageType;
  }

  static PageType fromName(String name) {
    return values.firstWhere((type) => name.startsWith(type.tag));
  }
}

@freezed
class Page with _$Page {
  const factory Page({
    required String id,
    @JsonKey(name: "name") required String pageName,
    required PageType type,
    @Default([]) List<Entry> entries,
    @Default("") String chapter,
    @Default(0) int priority,
  }) = _Page;

  factory Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);
}

extension PageExtension on Page {
  void updatePage(PassingRef ref, Page Function(Page) update) {
    // If multiple updates are done at the same time, `this` might be outdated. So we need to get the latest version.
    final currentPage = ref.read(pageProvider(id));
    if (currentPage == null) {
      return;
    }
    final newPage = update(currentPage);
    ref.read(bookProvider.notifier).insertPage(newPage);
  }

  Future<void> changeChapter(PassingRef ref, String newChapter) async {
    updatePage(
      ref,
      (page) => page.copyWith(chapter: newChapter),
    );
    await ref
        .read(communicatorProvider)
        .changePageValue(id, "chapter", newChapter);
  }

  Future<void> changePriority(PassingRef ref, int newPriority) async {
    updatePage(
      ref,
      (page) => page.copyWith(priority: newPriority),
    );
    await ref
        .read(communicatorProvider)
        .changePageValue(id, "priority", newPriority);
  }

  Future<void> createEntry(PassingRef ref, Entry entry) async {
    updatePage(
      ref,
      (page) => _insertEntry(page, entry),
    );
    await ref.read(communicatorProvider).createEntry(id, entry);
  }

  Future<void> updateEntireEntry(PassingRef ref, Entry entry) async {
    updatePage(
      ref,
      (page) => _insertEntry(page, entry),
    );
    await ref.read(communicatorProvider).updateEntireEntry(id, entry);
  }

  Future<void> updateEntryValue(
    PassingRef ref,
    Entry entry,
    String path,
    dynamic value,
  ) async {
    updatePage(
      ref,
      (page) => _insertEntry(page, entry.copyWith(path, value)),
    );
    await ref.read(communicatorProvider).updateEntry(id, entry.id, path, value);
  }

  void reorderEntry(PassingRef ref, String entryId, int newIndex) {
    syncReorderEntry(ref, entryId, newIndex);
    ref.read(communicatorProvider).reorderEntry(id, entryId, newIndex);
  }

  void syncReorderEntry(PassingRef ref, String entryId, int newIndex) {
    updatePage(
      ref,
      (page) {
        final entries = [...page.entries];

        final oldIndex = entries.indexWhere((entry) => entry.id == entryId);
        if (oldIndex == -1) {
          return page;
        }

        final entry = entries.removeAt(oldIndex);

        if (newIndex > oldIndex) {
          entries.insert(newIndex - 1, entry);
        } else {
          entries.insert(newIndex, entry);
        }

        return page.copyWith(entries: entries);
      },
    );
  }

  /// This should only be used to sync the entry from the server.
  void syncInsertEntry(PassingRef ref, Entry entry) {
    updatePage(ref, (page) => _insertEntry(page, entry));
  }

  Page _insertEntry(Page page, Entry entry) {
    // If the entry already exists, replace it.
    final entryExists = page.entries.any((e) => e.id == entry.id);
    if (entryExists) {
      return page.copyWith(
        entries: page.entries.map((e) => e.id == entry.id ? entry : e).toList(),
      );
    }

    // Otherwise, just add it to the end.
    return page.copyWith(
      entries: [...page.entries, entry],
    );
  }

  void deleteEntry(PassingRef ref, Entry entry) {
    ref.read(communicatorProvider).deleteEntry(id, entry.id);
    updatePage(
      ref,
      (page) => page.copyWith(
        entries: [
          ...page.entries
              .where((e) => e.id != entry.id)
              .map((e) => _removedReferencesFromEntry(ref, e, entry.id)),
        ],
      ),
    );
    // Also delete all references to this entry from other pages.
    ref.read(bookProvider).pages.where((page) => page.id != id).forEach((page) {
      page.removeReferencesTo(ref, entry.id);
    });

    // If the entry is selected, deselect it.
    if (ref.read(inspectingEntryIdProvider) == entry.id) {
      ref.read(inspectingEntryIdProvider.notifier).clearSelection();
    }
  }

  void removeReferencesTo(PassingRef ref, String entryId) {
    updatePage(
      ref,
      (page) => page.copyWith(
        entries: [
          ...page.entries
              .map((e) => _removedReferencesFromEntry(ref, e, entryId)),
        ],
      ),
    );
  }

  /// When an entry is delete all references in other entries need to be removed.
  Entry _removedReferencesFromEntry(
    PassingRef ref,
    Entry entry,
    String targetId,
  ) {
    final referenceEntryPaths =
        ref.read(modifierPathsProvider(entry.blueprintId, "entry"));

    final referenceEntryIds = referenceEntryPaths
        .expand((path) => entry.getAll(path))
        .expand((value) {
      if (value is String) {
        return [value];
      }
      // The keys of a map can also be entries
      if (value is Map) {
        return value.keys.map((key) => key.toString());
      }

      return <String>[];
    }).toList();

    if (!referenceEntryIds.contains(targetId)) {
      return entry;
    }

    final newEntry = referenceEntryPaths.fold(
      entry,
      (previousEntry, path) => previousEntry.copyMapped(
        path,
        (value) {
          if (value is String && value == targetId) {
            return null;
          }
          if (value is Map && value.containsKey(targetId)) {
            return value.where((key, value) => key != targetId).toMap();
          }
          return value;
        },
      ),
    );

    ref.read(communicatorProvider).updateEntireEntry(id, newEntry);

    return newEntry;
  }

  /// This should only be used to sync the entry from the server.
  void syncDeleteEntry(PassingRef ref, String entryId) {
    ref.read(bookProvider.notifier).insertPage(
          copyWith(
            entries: [...entries.where((e) => e.id != entryId)],
          ),
        );
  }
}

/// These are specialized shortcuts for common operations.
extension PageX on Page {
  Future<Entry> createEntryFromBlueprint(
    PassingRef ref,
    EntryBlueprint blueprint, {
    required DataBlueprint? genericBlueprint,
  }) async {
    final entry = Entry.fromBlueprint(
      id: getRandomString(),
      blueprint: blueprint,
      genericBlueprint: genericBlueprint,
    );
    await createEntry(ref, entry);
    return entry;
  }

  /// Will connects an entry to another entry on a given path.
  /// If it is already connected, it will remove the connection.
  Future<void> wireEntryToOtherEntry(
    PassingRef ref,
    Entry baseEntry,
    String targetEntryId,
    String path,
  ) async {
    final parts = path.split(".");
    final lastPart = parts.last;
    if (int.tryParse(lastPart) == null) {
      // We are setting an exact value. Not a list. So we just overwrite it.
      final value = baseEntry.get(path) == targetEntryId ? null : targetEntryId;
      await updateEntryValue(ref, baseEntry, path, value);
      return;
    }

    // If we have a list, we want to toggle the connection.
    final parentPath = parts.sublist(0, parts.length - 1).join(".");
    final currentTriggers = baseEntry.get(parentPath);
    if (currentTriggers == null || currentTriggers is! List) {
      debugPrint(
        "Invalid path for wiring entry ${baseEntry.id} to target entry $targetEntryId. $path is not a list.",
      );
      return;
    }

    final currentTriggersIds = currentTriggers.cast<String>();
    final List<String> newTriggers;

    if (currentTriggers.contains(targetEntryId)) {
      newTriggers =
          currentTriggersIds.where((id) => id != targetEntryId).toList();
    } else {
      newTriggers = currentTriggersIds + [targetEntryId];
    }

    await updateEntryValue(ref, baseEntry, parentPath, newTriggers);
  }

  Future<void> duplicateEntry(PassingRef ref, String entryId) async {
    final entry = ref.read(globalEntryProvider(entryId));
    if (entry == null) return;

    final modifiers =
        ref.read(fieldModifiersProvider(entry.blueprintId, "entry"));

    final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
    if (blueprint == null) return;

    final pageType = PageType.fromBlueprint(blueprint);

    final tags = pageType.linkingTags;

    // Remove the paths with the same modifier.
    final resetPaths = modifiers.entries
        .where((e) => tags.contains(e.value.data))
        .map((e) => e.key)
        .toList();

    final newEntry = resetPaths
        .fold(
          entry.copyWith("id", getRandomString()),
          (previousEntry, path) => previousEntry.copyMapped(
            path,
            (_) => null,
          ), // Remove all triggers
        )
        .copyWith("name", entry.name.incrementedName);
    await createEntry(ref, newEntry);
  }

  Future<void> linkWithDuplicate(
    PassingRef ref,
    String entryId,
    String path,
  ) async {
    final entry = ref.read(globalEntryProvider(entryId));
    if (entry == null) return;

    final modifiers =
        ref.read(fieldModifiersProvider(entry.blueprintId, "entry"));

    final wildPath = path.wild();
    final pathModifier = modifiers[wildPath];
    if (pathModifier == null) {
      debugPrint(
        "No modifier found for path $wildPath in entry ${entry.id}.",
      );
      return;
    }

    // Remove the paths with the same modifier.
    final resetPaths = modifiers.entries
        .where((e) => e.value.data == pathModifier.data)
        .map((e) => e.key)
        .toList();

    final newEntry = resetPaths
        .fold(
          entry.copyWith("id", getRandomString()),
          (previousEntry, path) => previousEntry.copyMapped(
            path,
            (_) => null,
          ), // Remove all triggers
        )
        .copyWith("name", entry.name.incrementedName);
    await createEntry(ref, newEntry);

    await wireEntryToOtherEntry(ref, entry, newEntry.id, path);
  }

  void linkWith(PassingRef ref, String entryId, String path) {
    final entry = ref.read(entryProvider(id, entryId));
    if (entry == null) return;
    final modifiers =
        ref.read(fieldModifiersProvider(entry.blueprintId, "entry"));

    final wildPath = path.wild();
    final pathModifier = modifiers[wildPath];
    if (pathModifier == null) {
      debugPrint(
        "No modifier found for path $wildPath in entry ${entry.id}.",
      );
      return;
    }

    final tag = pathModifier.data;

    // If the path has a only_tags modifier, we can only link to entries any of those tags and the tag of the entry.
    final onlyTagsModifier =
        ref.read(fieldModifiersProvider(entry.blueprintId, "only_tags"));

    final onlyTags = onlyTagsModifier[wildPath];
    final List<String> tags;
    if (onlyTags != null) {
      tags = onlyTags.data.split(",");
    } else {
      tags = [tag];
    }

    ref.read(searchProvider.notifier).asBuilder()
      ..anyTag(tags, canRemove: false)
      ..nonGenericAddEntry()
      ..fetchNewEntry(
        onAdded: (newEntry) async {
          await wireEntryToOtherEntry(ref, entry, newEntry.id, path);
          return null;
        },
      )
      ..fetchEntry(
        onSelect: (selectedEntry) async {
          await wireEntryToOtherEntry(ref, entry, selectedEntry.id, path);
          return null;
        },
      )
      ..excludeEntry(entryId, canRemove: false)
      ..open();
  }

  bool canHave(EntryBlueprint blueprint) => blueprint.tags.contains(type.tag);

  void deleteEntryWithConfirmation(
    BuildContext context,
    PassingRef ref,
    String entryId,
  ) {
    showConfirmationDialogue(
      context: context,
      title: "Delete Entry",
      content: "Are you sure you want to delete this entry?",
      confirmText: "Delete",
      onConfirm: () {
        final entry = ref.read(entryProvider(id, entryId));
        if (entry == null) return;
        deleteEntry(ref, entry);
      },
    );
  }
}
