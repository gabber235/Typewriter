import "package:faker/faker.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";

const defaultBlueprintIcons = <String>[
  "fa-solid:star",
  "fa-solid:bookmark",
  "fa-solid:bolt",
  "fa-solid:dragon",
  "fa-solid:ghost",
  "fa-solid:scroll",
  "fa7-solid:magic-wand-sparkles",
  "fa-solid:gem",
  "fa-solid:heart",
  "fa-solid:chess-knight",
];

String generateRandomIconName() => Fa6Solid.iconsList.randomOrNull()!;

/// Generate a random DataBlueprint, recursing up to [maxDepth].
///
/// The generator includes all blueprint kinds: primitive, enum, list, map,
/// object, algebraic and a few known custom editors.
DataBlueprint generateRandomDataBlueprint({
  int depth = 0,
  int maxDepth = 2,
  bool allowCustom = true,
}) {
  final terminal = depth >= maxDepth;
  final choices = <String>[
    "primitive",
    "enum",
    if (!terminal) "list",
    if (!terminal) "map",
    if (!terminal) "object",
    if (!terminal) "algebraic",
    if (allowCustom) "custom",
  ];

  final kind = choices[faker.randomGenerator.integer(choices.length)];
  switch (kind) {
    case "primitive":
      return generateRandomPrimitiveBlueprint();
    case "enum":
      return generateRandomEnumBlueprint();
    case "list":
      return generateRandomListBlueprint(depth: depth + 1, maxDepth: maxDepth);
    case "map":
      return generateRandomMapBlueprint(depth: depth + 1, maxDepth: maxDepth);
    case "object":
      return generateRandomObjectBlueprint(
        depth: depth + 1,
        maxDepth: maxDepth,
      );
    case "algebraic":
      return generateRandomAlgebraicBlueprint(
        depth: depth + 1,
        maxDepth: maxDepth,
      );
    case "custom":
      return generateRandomCustomBlueprint();
    default:
      return generateRandomPrimitiveBlueprint();
  }
}

/// Generate a random Primitive blueprint with optional sensible modifiers.
PrimitiveBlueprint generateRandomPrimitiveBlueprint() {
  final pick = faker.randomGenerator.integer(4);
  switch (pick) {
    case 0:
      return DataBlueprint.string(
            defaultValue: faker.lorem
                .words(faker.randomGenerator.integer(3, min: 1))
                .join(" "),
            modifiers: _randomStringModifiers(),
          )
          as PrimitiveBlueprint;
    case 1:
      return DataBlueprint.integer(
            defaultValue: faker.randomGenerator.integer(1000, min: -100),
            modifiers: _randomNumberModifiers(),
          )
          as PrimitiveBlueprint;
    case 2:
      return DataBlueprint.decimal(
            defaultValue: double.parse(
              faker.randomGenerator.decimal(scale: 100).toStringAsFixed(2),
            ),
            modifiers: _randomNumberModifiers(),
          )
          as PrimitiveBlueprint;
    case 3:
    default:
      return DataBlueprint.boolean(
            defaultValue: faker.randomGenerator.boolean(),
            modifiers: _randomBaseModifiers(),
          )
          as PrimitiveBlueprint;
  }
}

/// Generate a random Enum blueprint.
EnumBlueprint generateRandomEnumBlueprint() {
  final count = faker.randomGenerator.integer(6, min: 2);
  final set = <String>{};
  while (set.length < count) {
    set.add(faker.lorem.word().toLowerCase());
  }
  final values = set.toList();
  final defaultValue = values[faker.randomGenerator.integer(values.length)];

  return DataBlueprint.enumBlueprint(
        values: values,
        internalDefaultValue: defaultValue,
        modifiers: _randomBaseModifiers(),
      )
      as EnumBlueprint;
}

/// Generate a random List blueprint.
ListBlueprint generateRandomListBlueprint({int depth = 0, int maxDepth = 2}) {
  final type = generateRandomDataBlueprint(depth: depth, maxDepth: maxDepth);
  return DataBlueprint.list(
        type: type,
        modifiers: [..._randomBaseModifiers(), const ExpandedModifier()],
      )
      as ListBlueprint;
}

/// Generate a random Map blueprint.
///

MapBlueprint generateRandomMapBlueprint({int depth = 0, int maxDepth = 2}) {
  final keyChoices = <DataBlueprint>[
    DataBlueprint.string(modifiers: _randomStringModifiers()),
    generateRandomEnumBlueprint(),
  ];
  final key = keyChoices[faker.randomGenerator.integer(keyChoices.length)];
  final value = generateRandomDataBlueprint(depth: depth, maxDepth: maxDepth);

  return DataBlueprint.map(
        key: key,
        value: value,
        modifiers: [..._randomBaseModifiers(), const ExpandedModifier()],
      )
      as MapBlueprint;
}

/// Generate a random Object blueprint with 1-5 fields.
ObjectBlueprint generateRandomObjectBlueprint({
  int depth = 0,
  int maxDepth = 2,
}) {
  final fields = <String, DataBlueprint>{};
  final count = faker.randomGenerator.integer(5, min: 1);
  while (fields.length < count) {
    final key = _randomFieldName();
    fields[key] = generateRandomDataBlueprint(depth: depth, maxDepth: maxDepth);
  }

  return DataBlueprint.object(
        fields: fields,
        modifiers: [..._randomBaseModifiers(), const ExpandedModifier()],
      )
      as ObjectBlueprint;
}

/// Generate a random Algebraic blueprint with 2-4 cases.
AlgebraicBlueprint generateRandomAlgebraicBlueprint({
  int depth = 0,
  int maxDepth = 2,
}) {
  final cases = <String, DataBlueprint>{};
  final count = faker.randomGenerator.integer(4, min: 2);
  while (cases.length < count) {
    final name = _randomVariantName();
    cases[name] = generateRandomDataBlueprint(depth: depth, maxDepth: maxDepth);
  }
  return DataBlueprint.algebraic(
        cases: cases,
        modifiers: _randomBaseModifiers(),
      )
      as AlgebraicBlueprint;
}

/// Generate a random Custom blueprint from well-known editors.
CustomBlueprint generateRandomCustomBlueprint() {
  // Return a basic custom blueprint since no specialized custom editors remain
  return DataBlueprint.custom(
        editor: "custom_editor",
        shape: DataBlueprint.object(fields: {}),
      )
      as CustomBlueprint;
}

List<Modifier> _randomBaseModifiers() {
  final mods = <Modifier>[];
  if (faker.randomGenerator.boolean()) mods.add(const ReadOnlyModifier());
  if (faker.randomGenerator.boolean()) mods.add(const ExpandedModifier());
  if (faker.randomGenerator.integer(10) == 0) {
    mods.add(
      const CustomModifier(name: "debug_hint", data: {"note": "generated"}),
    );
  }
  return mods;
}

List<Modifier> _randomStringModifiers() {
  final mods = _randomBaseModifiers();
  if (faker.randomGenerator.boolean()) mods.add(const MultilineModifier());
  if (faker.randomGenerator.boolean()) mods.add(const SnakeCaseModifier());
  if (faker.randomGenerator.integer(5) == 0) {
    mods.add(const GeneratedModifier());
  }
  if (faker.randomGenerator.integer(6) == 0) {
    final tag = _randomEntryTag();
    mods.add(Modifier.entryReference(tag));
  } else if (faker.randomGenerator.integer(7) == 0) {
    final tags = List.generate(
      faker.randomGenerator.integer(3, min: 2),
      (_) => _randomEntryTag(),
    );
    mods.add(Modifier.anyEntryReference(tags));
  }
  return mods;
}

List<Modifier> _randomNumberModifiers() {
  final mods = _randomBaseModifiers();
  if (faker.randomGenerator.boolean()) {
    final minVal = faker.randomGenerator.integer(50, min: -50);
    final maxVal = faker.randomGenerator.integer(100, min: minVal);
    mods.add(Modifier.min(minVal));
    mods.add(Modifier.max(maxVal));
  }
  if (faker.randomGenerator.integer(4) == 0) {
    mods.add(const NegativeModifier());
  }
  return mods;
}

String _randomFieldName() {
  final words = faker.randomGenerator.integer(3, min: 1);
  final raw = faker.lorem.words(words).join("_");
  return raw.toLowerCase().replaceAll(RegExp(r"[^a-z0-9_]+"), "_");
}

String _randomVariantName() {
  final word = faker.lorem.word();
  return word.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_");
}

String _randomEntryTag() {
  const tags = ["basic", "combat", "dialogue", "quest", "npc", "item", "scene"];
  return tags[faker.randomGenerator.integer(tags.length)];
}
