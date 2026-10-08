import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/testing.dart";

export "features/features.dart";

final fixturePageType = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "fixture", name: "Page"),
    ),
    revision: 1,
  ),
  arguments: const [],
);

Page generateRandomPage([skir.NamedTypeUse? pageType]) {
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

  final chapter = chapters.randomOrNull() ?? "";
  final priority = faker.randomGenerator.integer(100, min: -10);
  final configuration = skir.TypeSelection.wrapComplete(
    pageType ?? fixturePageType,
  );
  return Page(
    authoredRecord: skir.AuthoringRecord(
      configuration: configuration,
      fields: [
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue(pageName),
        ),
        skir.FieldValue(
          name: "chapter",
          value: skir.DataValue.wrapStringValue(chapter),
        ),
        skir.FieldValue(
          name: "priority",
          value: skir.DataValue.wrapInteger(priority.toString()),
        ),
      ],
    ),
    pageId: skir.ResourceId(value: "page:${faker.guid.guid()}"),
    bookId: skir.ResourceId(value: "book:${faker.guid.guid()}"),
    name: pageName,
    configuration: configuration,
    chapter: chapter,
    priority: priority,
  );
}

class BookPagesMock extends CanonicalBookPages {
  BookPagesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<Page>> build(skir.ResourceId bookId) async {
    await ref.debounce(300.ms);
    await Future<void>.delayed(100.ms);
    return displayState.generate(generateRandomPage);
  }
}

class PagesMock extends CanonicalPage {
  PagesMock({this.page, this.pageType});

  final Page? page;
  final skir.NamedTypeUse? pageType;

  @override
  Future<Page> build(skir.ResourceId pageId) async {
    await Future<void>.delayed(50.ms);
    if (page case final page?) return page;
    return generateRandomPage(pageType).copyWith(pageId: pageId);
  }
}

List<Override> bookPagesProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [
  canonicalBookPagesProvider.overrideWith2(
    (_) => BookPagesMock(displayState: state),
  ),
];

List<Override> pagesProviderOverrides({
  Page? page,
  skir.NamedTypeUse? pageType,
}) => [
  canonicalPageProvider.overrideWith2(
    (_) => PagesMock(page: page, pageType: pageType),
  ),
];

List<Override> pageIdProviderOverrides({String? pageId}) => [
  pageIdProvider.overrideWith(
    (ref) => pageId == null ? null : skir.ResourceId(value: "page:$pageId"),
  ),
];

List<Override> bookIdProviderOverrides({String? bookId}) => [
  bookIdProvider.overrideWith(
    (ref) => bookId == null ? null : skir.ResourceId(value: "book:$bookId"),
  ),
];
