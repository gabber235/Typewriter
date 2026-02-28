import "dart:math" as math;

import "package:collection/collection.dart";
import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";

// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/pages/pages.dart";
import "package:typewriter_panel/logic/pages/graph_direction.dart";

import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/src/mocks/graph_layout.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

// ============ ENTRY-SPECIFIC LAYOUT FUNCTIONS ============

/// Organizes entries into random layers for flow graphs
List<List<EntryDefinition>> organizeEntriesRandomly(
  List<EntryDefinition> entries,
) {
  final numLayers = math.max(2, math.min(20, (entries.length / 2).ceil()));
  return distributeIntoLayers(entries, numLayers);
}

/// Generates edges between adjacent layers
List<EntryEdge> generateEdgesForLayers(List<List<EntryDefinition>> layers) {
  final edges = <EntryEdge>[];
  final random = math.Random();

  for (int i = 0; i < layers.length - 1; i++) {
    final currentLayer = layers[i];
    final nextLayer = layers[i + 1];

    for (final entry in currentLayer) {
      final numEdges = random.nextInt(math.min(3, nextLayer.length)) + 1;
      final targets = nextLayer.toList()..shuffle(random);

      for (int j = 0; j < numEdges && j < targets.length; j++) {
        edges.add(
          EntryEdge(id: entry.id, otherId: targets[j].id, path: "default"),
        );
      }
    }
  }

  return edges;
}

/// Applies edges to entries
List<EntryDefinition> applyEdgesToEntries(
  List<EntryDefinition> entries,
  List<EntryEdge> edges,
) {
  final inwardMap = <String, List<EntryEdge>>{};
  final outwardMap = <String, List<EntryEdge>>{};

  for (final edge in edges) {
    inwardMap.putIfAbsent(edge.otherId, () => []).add(edge);
    outwardMap.putIfAbsent(edge.id, () => []).add(edge);
  }

  return entries.map((entry) {
    return entry.copyWith(
      inwardEdges: inwardMap[entry.id] ?? const [],
      outwardEdges: outwardMap[entry.id] ?? const [],
    );
  }).toList();
}

/// Main entry layout function
List<EntryDefinition> generateEntryGraphLayout(
  List<EntryDefinition> entries,
  GraphDirection? direction,
) {
  if (entries.isEmpty) return entries;

  final random = math.Random();
  direction ??= GraphDirection.values[random.nextInt(4)];

  final placements = generateDynamicLayout(
    items: entries,
    getId: (e) => e.id,
    organizeIntoLayers: organizeEntriesRandomly,
    direction: direction,
  );

  final positioned = entries.map((entry) {
    final p = placements[entry.id];
    if (p == null) return entry;
    return entry.copyWith(
      placement: EntryPlacement(
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height,
      ),
    );
  }).toList();

  // Rebuild layers for edge generation
  final layers = organizeEntriesRandomly(positioned);
  final edges = generateEdgesForLayers(layers);

  return applyEdgesToEntries(positioned, edges);
}

Page generateRandomPage([PageType? pageType]) {
  final pageTypes = PageType.values.toList();
  final type = pageType ?? pageTypes.randomOrNull()!;
  final pageName = faker.lorem
      .words(faker.randomGenerator.integer(3, min: 1))
      .join("_")
      .snakeCase();
  final chapters = [
    "",
    "intro",
    "example.test",
    "main",
    "main.side_quests",
    "main.epilogue",
  ];

  return Page()
    ..id = faker.guid.guid()
    ..name = pageName
    ..type = type
    ..chapter = chapters.randomOrNull() ?? ""
    ..priority = faker.randomGenerator.integer(100, min: -10);
}

class BookPagesMock extends BookPages {
  BookPagesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<Page>> build(String bookId, String search) async {
    await ref.debounce(300.ms);
    await Future<void>.delayed(100.ms);
    final pages = await displayState.generate(generateRandomPage);

    if (search.isEmpty) return pages;

    return pages
        .where(
          (page) =>
              page.name.toLowerCase().contains(search.toLowerCase()) ||
              page.chapter.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
  }
}

class PagesMock extends Pages {
  PagesMock({this.page, this.pageType});

  final Page? page;
  final PageType? pageType;

  @override
  Future<Page> build(String pageId) async {
    await Future<void>.delayed(50.ms);
    if (page != null) return page!;
    final randomPage = generateRandomPage(pageType);
    return randomPage.deepCopy()..id = pageId;
  }

  @override
  Future<void> changeChapter(String chapter) async {
    await Future<void>.delayed(200.ms);
  }

  @override
  Future<void> renamePage(String name) async {
    await Future<void>.delayed(200.ms);
  }

  @override
  Future<void> changePriority(int priority) async {
    await Future<void>.delayed(200.ms);
  }
}

class PageEntriesMock extends PageEntries {
  PageEntriesMock({required this.displayState, this.direction});

  final DisplayState displayState;
  final GraphDirection? direction;

  @override
  Future<List<PageEntry>> build(String pageId) async {
    await Future<void>.delayed(100.ms);
    final definitions = await displayState.generate(
      generateRandomEntryDefinition,
    );

    final entries = generateEntryGraphLayout(definitions, direction);

    return entries.map((def) => PageEntry.definition(definition: def)).toList();
  }

  @override
  Future<void> moveAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    optimisticMoveAll(changed);
  }

  @override
  Future<void> resizeAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    optimisticResizeAll(changed);
  }
}

class EntryMock extends Entry {
  EntryMock({this.definition});

  final EntryDefinition? definition;

  @override
  Future<EntryDefinition?> build(String entryId) async {
    await Future<void>.delayed(200.ms);
    if (definition != null) return definition;

    final currentPageId = ref.read(pageIdProvider);

    final pageEntries = await ref.read(
      pageEntriesProvider(currentPageId ?? "").future,
    );

    final pageEntry = pageEntries.firstWhereOrNull(
      (entry) => entry.id == entryId,
    );

    return switch (pageEntry) {
      DefinitionPageEntry(:final definition) => definition,
      _ => generateRandomEntryDefinition().copyWith(id: entryId),
    };
  }

  @override
  Future<void> updateFieldValue(String path, dynamic value) async {
    await Future<void>.delayed(200.ms);
  }

  @override
  Future<void> moveToPage(String pageId) async {
    await Future<void>.delayed(200.ms);
  }
}

List<Override> bookPagesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [
  bookPagesProvider.overrideWith(() => BookPagesMock(displayState: state)),
];

List<Override> pagesProviderOverrides({Page? page, PageType? pageType}) => [
  pagesProvider.overrideWith(() => PagesMock(page: page, pageType: pageType)),
];

List<Override> pageEntriesProviderOverrides({
  DisplayState state = DisplayState.loading,
  GraphDirection? direction,
}) => [
  pageEntriesProvider.overrideWith(
    () => PageEntriesMock(displayState: state, direction: direction),
  ),
];

List<Override> entryProviderOverrides({EntryDefinition? definition}) => [
  entryProvider.overrideWith(() => EntryMock(definition: definition)),
];

List<Override> pageIdProviderOverrides({String? pageId}) => [
  pageIdProvider.overrideWith((ref) => pageId),
];

List<Override> bookIdProviderOverrides({String? bookId}) => [
  bookIdProvider.overrideWith((ref) => bookId),
];
