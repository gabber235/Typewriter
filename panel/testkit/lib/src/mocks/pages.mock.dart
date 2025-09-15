import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";

// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/books.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/pages.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

Page generateRandomPage() {
  final pageTypes = PageType.values;
  final type = pageTypes.randomOrNull()!;
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
    "main.epilogue"
  ];

  return Page(
    id: faker.guid.guid(),
    pageName: pageName,
    type: type,
    color: safeColors.randomOrNull(),
    chapter: chapters.randomOrNull() ?? "",
    priority: faker.randomGenerator.integer(100, min: -10),
  );
}

EntryBlueprint generateRandomEntryBlueprint() {
  final extensions = ["basic", "combat", "dialogue", "quest", "npc"];

  return EntryBlueprint(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" ").formatted,
    description: faker.lorem.sentence(),
    extension: extensions.randomOrNull()!,
    dataBlueprint: ObjectBlueprint(fields: {}),
    color: safeColors.randomOrNull()!,
    icon: "fa-solid:star",
    tags: List.generate(
      faker.randomGenerator.integer(3, min: 0),
      (_) => faker.lorem.word(),
    ),
  );
}

EntryDefinition generateRandomEntryDefinition() {
  return EntryDefinition(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" ").formatted,
    blueprint: generateRandomEntryBlueprint(),
    data: DynamicData({}),
  );
}

EntryIdentifier generateRandomEntryIdentifier() {
  return EntryIdentifier(faker.guid.guid());
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
        .where((page) =>
            page.pageName.toLowerCase().contains(search.toLowerCase()) ||
            page.chapter.toLowerCase().contains(search.toLowerCase()))
        .toList();
  }
}

class PagesMock extends Pages {
  PagesMock({this.page});

  final Page? page;

  @override
  Future<Page> build(String pageId) async {
    await Future<void>.delayed(50.ms);
    return page ?? generateRandomPage().copyWith(id: pageId);
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
  PageEntriesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<String>> build(String pageId) async {
    await Future<void>.delayed(100.ms);
    final entries = await displayState.generate(() => faker.guid.guid());
    return entries;
  }
}

class EntryMock extends Entry {
  EntryMock({this.definition});

  final EntryDefinition? definition;

  @override
  Future<EntryDefinition?> build(String entryId) async {
    await Future<void>.delayed(50.ms);
    return definition ?? generateRandomEntryDefinition().copyWith(id: entryId);
  }

  @override
  Future<void> updateFieldValue(String path, dynamic value) async {
    await Future<void>.delayed(200.ms);
  }

  @override
  Future<void> moveToPage(String pageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

BookPagesMock createBookPagesMockForState(DisplayState state) {
  return BookPagesMock(displayState: state);
}

PagesMock createPagesMock({Page? page}) {
  return PagesMock(page: page);
}

PageEntriesMock createPageEntriesMockForState(DisplayState state) {
  return PageEntriesMock(displayState: state);
}

EntryMock createEntryMock({EntryDefinition? definition}) {
  return EntryMock(definition: definition);
}

List<Override> bookPagesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [
      bookPagesProvider.overrideWith(
        () => createBookPagesMockForState(state),
      ),
    ];

List<Override> pagesProviderOverrides({
  Page? page,
}) =>
    [
      pagesProvider.overrideWith(() => createPagesMock(page: page)),
    ];

List<Override> pageEntriesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) =>
    [
      pageEntriesProvider.overrideWith(
        () => createPageEntriesMockForState(state),
      ),
    ];

List<Override> entryProviderOverrides({
  EntryDefinition? definition,
}) =>
    [
      entryProvider.overrideWith(() => createEntryMock(definition: definition)),
    ];

List<Override> pageIdProviderOverrides({
  String? pageId,
}) =>
    [
      pageIdProvider.overrideWith((ref) => pageId),
    ];

List<Override> bookIdProviderOverrides({
  String? bookId,
}) =>
    [
      bookIdProvider.overrideWith((ref) => bookId),
    ];

List<Override> allPagesProviderOverrides({
  DisplayState pagesState = DisplayState.manyItems,
  DisplayState entriesState = DisplayState.fewItems,
  String? selectedPageId,
  String? currentBookId,
  Page? specificPage,
  EntryDefinition? specificEntry,
}) =>
    [
      ...bookPagesProviderOverrides(state: pagesState),
      ...pagesProviderOverrides(page: specificPage),
      ...pageEntriesProviderOverrides(state: entriesState),
      ...entryProviderOverrides(definition: specificEntry),
      ...pageIdProviderOverrides(pageId: selectedPageId),
      ...bookIdProviderOverrides(bookId: currentBookId ?? "test-book-id"),
    ];
