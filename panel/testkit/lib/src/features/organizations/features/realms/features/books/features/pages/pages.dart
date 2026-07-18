import "package:collection/collection.dart";
import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/application/books.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/application/pages.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/entries.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/graph_direction.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";
import "package:typewriter_panel/shared/utilities/string.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/entries.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/testing/graph_layout.dart";
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/scene.dart";
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

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
    ..pageId = faker.guid.guid()
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
    return randomPage.deepCopy()..pageId = pageId;
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

class PageElementsMock extends PageElements {
  PageElementsMock({
    required this.displayState,
    this.direction,
    this.pageType,
    this.overwriteElements,
  });

  final DisplayState displayState;
  final GraphDirection? direction;
  final PageType? pageType;
  final List<PageElement>? overwriteElements;

  @override
  Future<List<PageElement>> build(String pageId) async {
    await Future<void>.delayed(100.ms);
    if (overwriteElements != null) return overwriteElements!;
    if (pageType == PageType.PAGE_TYPE_SCENE) {
      return displayState.generateBatch(generateRandomScenePageElements);
    }

    final definitions = await displayState.generate(
      generateRandomEntryDefinition,
    );

    final entries = generateDynamicGraphLayout(definitions, direction);

    return entries
        .map(
          (def) =>
              PageElement.entry(entry: PageEntry.definition(definition: def)),
        )
        .toList();
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

    final pageElements = await ref.read(
      pageElementsProvider(currentPageId?.id ?? "").future,
    );

    final pageElement = pageElements.firstWhereOrNull(
      (element) => element.id == entryId,
    );

    return switch (pageElement) {
      PageElementEntry(:final entry) => switch (entry) {
        DefinitionPageEntry(:final definition) => definition,
        _ => null,
      },
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
  bookPagesProvider.overrideWith2((_) => BookPagesMock(displayState: state)),
];

List<Override> pagesProviderOverrides({Page? page, PageType? pageType}) => [
  pagesProvider.overrideWith2((_) => PagesMock(page: page, pageType: pageType)),
];

List<Override> pageElementsProviderOverrides({
  DisplayState state = DisplayState.loading,
  PageType? pageType,
  GraphDirection? direction,
  List<PageElement>? overwriteElements,
}) => [
  pageElementsProvider.overrideWith2(
    (_) => PageElementsMock(
      displayState: state,
      direction: direction,
      pageType: pageType,
      overwriteElements: overwriteElements,
    ),
  ),
];

List<Override> entryProviderOverrides({EntryDefinition? definition}) => [
  entryProvider.overrideWith2((_) => EntryMock(definition: definition)),
];

List<Override> pageIdProviderOverrides({String? pageId}) => [
  pageIdProvider.overrideWith(
    (ref) => pageId != null ? recordId("page:$pageId") : null,
  ),
];

List<Override> bookIdProviderOverrides({String? bookId}) => [
  bookIdProvider.overrideWith(
    (ref) => bookId != null ? recordId("book:$bookId") : null,
  ),
];
