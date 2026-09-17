import "package:collection/collection.dart";
import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/editor.dart";
import "package:typewriter_testkit/src/shared/testing/testing.dart";

export "features/features.dart";

const fixturePageKind = PageKindRef(id: "fixture.page", revision: 1);

Page generateRandomPage([PageKindRef pageKind = fixturePageKind]) {
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

  return Page(
    pageId: recordId("page:${faker.guid.guid()}"),
    bookId: recordId("book:${faker.guid.guid()}"),
    name: pageName,
    kind: pageKind,
    chapter: chapters.randomOrNull() ?? "",
    priority: faker.randomGenerator.integer(100, min: -10),
  );
}

class BookPagesMock extends CanonicalBookPages {
  BookPagesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<Page>> build(skir.RecordId bookId) async {
    await ref.debounce(300.ms);
    await Future<void>.delayed(100.ms);
    final pages = await displayState.generate(generateRandomPage);

    return pages;
  }
}

class PagesMock extends CanonicalPage {
  PagesMock({this.page, this.pageKind});

  final Page? page;
  final PageKindRef? pageKind;

  @override
  Future<Page> build(skir.RecordId pageId) async {
    await Future<void>.delayed(50.ms);
    if (page != null) {
      return page!;
    }
    final randomPage = generateRandomPage(pageKind ?? fixturePageKind);
    return randomPage.copyWith(pageId: pageId);
  }
}

class PageElementsMock extends PageElements {
  PageElementsMock({required this.displayState, this.elements});

  final DisplayState displayState;
  final List<PageElement>? elements;

  @override
  Future<List<PageElement>> build(
    skir.RecordId organizationId,
    skir.RecordId realmId,
    String pageId,
  ) async {
    await Future<void>.delayed(100.ms);
    return displayState.generateBatch((count) {
      if (elements case final elements?) return elements;
      final entries = layoutGraphEntries(
        List.generate(count, (_) => generateRandomEntryDefinition()),
        direction: GraphDirection.leftToRight,
      );
      return [
        for (final definition in entries)
          PageElement.entry(
            entry: PageEntry.definition(definition: definition),
          ),
      ];
    });
  }

  @override
  Future<void> moveAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    final positions = {for (final item in changed) item.$1: (item.$2, item.$3)};
    state = AsyncData([
      for (final element in state.requireValue)
        if (positions[element.id] case final position?)
          element.moveTo(position.$1, position.$2)
        else
          element,
    ]);
  }

  @override
  Future<void> resizeAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    final sizes = {for (final item in changed) item.$1: (item.$2, item.$3)};
    state = AsyncData([
      for (final element in state.requireValue)
        if (sizes[element.id] case final size?)
          element.resizeTo(size.$1, size.$2)
        else
          element,
    ]);
  }
}

class EntryMock extends Entry {
  EntryMock({this.definition});

  final EntryDefinition? definition;

  @override
  Future<EntryDefinition?> build(String entryId) async {
    await Future<void>.delayed(200.ms);
    if (definition != null) return definition;

    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    final currentPageId = ref.read(pageIdProvider);
    if (organizationId == null || realmId == null || currentPageId == null) {
      return null;
    }

    final pageElements = await ref.read(
      pageElementsProvider(organizationId, realmId, currentPageId.id).future,
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
  Future<void> updateFieldValue(DataPath path, DataValue value) async {
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
  canonicalBookPagesProvider.overrideWith2(
    (_) => BookPagesMock(displayState: state),
  ),
];

List<Override> pagesProviderOverrides({Page? page, PageKindRef? pageKind}) => [
  canonicalPageProvider.overrideWith2(
    (_) => PagesMock(page: page, pageKind: pageKind),
  ),
];

List<Override> pageElementsProviderOverrides({
  DisplayState state = DisplayState.loading,
  List<PageElement>? elements,
}) => [
  pageElementsProvider.overrideWith2(
    (_) => PageElementsMock(displayState: state, elements: elements),
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
