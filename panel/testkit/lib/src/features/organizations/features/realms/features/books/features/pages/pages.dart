import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:faker/faker.dart";

// ignore: depend_on_referenced_packages, implementation_imports

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
    pageId: skir.ResourceId(value: "page:${faker.guid.guid()}"),
    bookId: skir.ResourceId(value: "book:${faker.guid.guid()}"),
    name: pageName,
    configuration: configuration,
    chapter: chapter,
    priority: priority,
  );
}

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
