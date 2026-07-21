import "package:faker/faker.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/data_blueprint.dart";

ElementBlueprint generateRandomElementBlueprint() {
  final extensions = ["basic", "combat", "dialogue", "quest", "npc", "item"];

  return ElementBlueprint(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" ").formatted,
    description: faker.lorem.sentence(),
    extension: extensions.randomOrNull()!,
    dataBlueprint: generateRandomObjectBlueprint(maxDepth: 2),
    color: safeColors.randomOrNull()!,
    icon: generateRandomIconName(),
    tags:
        List.generate(
          faker.randomGenerator.integer(3, min: 0),
          (_) => faker.lorem.word(),
        ) +
        [PageType.values.randomOrNull()!.tag],
  );
}

EntryDefinition generateRandomEntryDefinition() {
  final width = faker.randomGenerator.integer(3, min: 2) * 50;
  final height = faker.randomGenerator.integer(3, min: 2) * 30;
  final blueprint = generateRandomElementBlueprint();

  final defaultData = blueprint.dataBlueprint.defaultValue();

  return EntryDefinition(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" ").formatted,
    blueprint: blueprint,
    placement: EntryPlacement(
      x: faker.randomGenerator.integer(400),
      y: faker.randomGenerator.integer(300),
      width: width,
      height: height,
    ),
    data: DynamicData(defaultData is Map<String, dynamic> ? defaultData : {}),
    inwardEdges: const [],
    outwardEdges: const [],
  );
}
