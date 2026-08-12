import "package:faker/faker.dart";
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/features/organizations/features/realms/features/books/features/pages/features/editor/typed_data.dart";

ElementDefinition generateRandomElementDefinition() {
  final extensions = ["basic", "combat", "dialogue", "quest", "npc", "item"];
  final namespace = extensions.randomOrNull()!;

  return ElementDefinition(
    rootType: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: namespace, name: faker.guid.guid()),
      revision: 1,
    ),
    name: faker.lorem.words(2).join(" ").formatted,
    description: faker.lorem.sentence(),
    color: safeColors.randomOrNull()!,
    icon: IconValue.iconify(generateRandomIconName()),
  );
}

EntryDefinition generateRandomEntryDefinition() {
  final width = faker.randomGenerator.integer(3, min: 2) * 50;
  final height = faker.randomGenerator.integer(3, min: 2) * 30;
  final elementDefinition = generateRandomElementDefinition();
  final data = generateRandomRecordData(maxDepth: 2).value;

  return EntryDefinition(
    id: faker.guid.guid(),
    name: faker.lorem.words(2).join(" ").formatted,
    elementDefinition: elementDefinition,
    placement: EntryPlacement(
      x: faker.randomGenerator.integer(400),
      y: faker.randomGenerator.integer(300),
      width: width,
      height: height,
    ),
    data: data,
    inwardEdges: const [],
    outwardEdges: const [],
  );
}
