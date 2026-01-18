import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";

void main() {
  group("EntryBlueprint.getField", () {
    test("returns field for simple path", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {"name": DataBlueprint.string()},
        ),
      );
      final field = blueprint.getField("name");
      expect(field, isNotNull);
      expect(field is PrimitiveBlueprint, isTrue);
    });

    test("returns field for nested object path", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "user": DataBlueprint.object(
              fields: {"email": DataBlueprint.string()},
            ),
          },
        ),
      );
      final field = blueprint.getField("user.email");
      expect(field, isNotNull);
      expect(field is PrimitiveBlueprint, isTrue);
    });

    test("returns list element type for list path", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {"items": DataBlueprint.list(type: DataBlueprint.string())},
        ),
      );
      final field = blueprint.getField("items.0");
      expect(field, isNotNull);
      expect(field is PrimitiveBlueprint, isTrue);
    });

    test("returns map value type for map path", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "settings": DataBlueprint.map(
              key: DataBlueprint.string(),
              value: DataBlueprint.integer(),
            ),
          },
        ),
      );
      final field = blueprint.getField("settings.someKey");
      expect(field, isNotNull);
      expect(field is PrimitiveBlueprint, isTrue);
    });

    test("returns null for non-existent path", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
      );
      final field = blueprint.getField("nonexistent.path");
      expect(field, isNull);
    });

    test("handles deeply nested paths", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "level1": DataBlueprint.object(
              fields: {
                "level2": DataBlueprint.object(
                  fields: {
                    "level3": DataBlueprint.string(defaultValue: "deep"),
                  },
                ),
              },
            ),
          },
        ),
      );
      final field = blueprint.getField("level1.level2.level3");
      expect(field, isNotNull);
    });
  });

  group("EntryBlueprint.fieldsWithModifier", () {
    test("finds fields with read-only modifier", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "id": DataBlueprint.string(modifiers: [const Modifier.readOnly()]),
            "name": DataBlueprint.string(),
          },
        ),
      );
      final fields = blueprint.fieldsWithModifier<ReadOnlyModifier>();
      expect(fields.containsKey("id"), isTrue);
      expect(fields.containsKey("name"), isFalse);
    });

    test("finds nested fields with modifiers", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "outer": DataBlueprint.object(
              fields: {
                "inner": DataBlueprint.string(
                  modifiers: [const Modifier.readOnly()],
                ),
              },
            ),
          },
        ),
      );
      final fields = blueprint.fieldsWithModifier<ReadOnlyModifier>();
      expect(fields.containsKey("outer.inner"), isTrue);
    });

    test("finds fields in lists with modifiers", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {
            "items": DataBlueprint.list(
              type: DataBlueprint.string(
                modifiers: [const Modifier.multiline()],
              ),
            ),
          },
        ),
      );
      final fields = blueprint.fieldsWithModifier<MultilineModifier>();
      expect(fields.containsKey("items.*"), isTrue);
    });

    test("returns empty map when no modifiers found", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(
          fields: {"name": DataBlueprint.string()},
        ),
      );
      final fields = blueprint.fieldsWithModifier<ReadOnlyModifier>();
      expect(fields, isEmpty);
    });
  });

  group("EntryBlueprint.isGeneric", () {
    test("returns false when genericConstraints is null", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: null,
      );
      expect(blueprint.isGeneric, isFalse);
    });

    test("returns true when genericConstraints is not null", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [],
      );
      expect(blueprint.isGeneric, isTrue);
    });

    test("returns true when genericConstraints has items", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [DataBlueprint.string()],
      );
      expect(blueprint.isGeneric, isTrue);
    });
  });

  group("EntryBlueprint.allowsGeneric", () {
    test("allows any when genericConstraints is null", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: null,
      );
      expect(blueprint.allowsGeneric(DataBlueprint.string()), isTrue);
      expect(blueprint.allowsGeneric(DataBlueprint.integer()), isTrue);
    });

    test("allows any when genericConstraints is empty", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [],
      );
      expect(blueprint.allowsGeneric(DataBlueprint.string()), isTrue);
    });

    test("allows matching blueprint", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [DataBlueprint.string()],
      );
      expect(blueprint.allowsGeneric(DataBlueprint.string()), isTrue);
    });

    test("rejects non-matching blueprint", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [DataBlueprint.string()],
      );
      expect(blueprint.allowsGeneric(DataBlueprint.integer()), isFalse);
    });

    test("rejects null blueprint when constraints exist", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [DataBlueprint.string()],
      );
      expect(blueprint.allowsGeneric(null), isFalse);
    });

    test("allows when any constraint matches", () {
      final blueprint = EntryBlueprint(
        id: "test",
        name: "Test",
        description: "Test entry",
        extension: "TestExtension",
        dataBlueprint: ObjectBlueprint(fields: {}),
        genericConstraints: [DataBlueprint.string(), DataBlueprint.integer()],
      );
      expect(blueprint.allowsGeneric(DataBlueprint.integer()), isTrue);
    });
  });

  group("EntryPlacement", () {
    test("center is calculated correctly", () {
      const placement = EntryPlacement(x: 100, y: 200, width: 50, height: 100);
      expect(placement.center, const Offset(125, 250));
    });

    test("center at origin", () {
      const placement = EntryPlacement(x: 0, y: 0, width: 100, height: 100);
      expect(placement.center, const Offset(50, 50));
    });

    test("distanceSquaredTo calculates correctly", () {
      const placement1 = EntryPlacement(x: 0, y: 0, width: 100, height: 100);
      const placement2 = EntryPlacement(x: 100, y: 0, width: 100, height: 100);

      final distance = placement1.distanceSquaredTo(placement2);
      expect(distance, 10000.0);
    });

    test("distanceSquaredTo same placement is zero", () {
      const placement = EntryPlacement(x: 100, y: 200, width: 50, height: 50);
      expect(placement.distanceSquaredTo(placement), 0.0);
    });
  });

  group("PageEntry extension", () {
    test("DefinitionPageEntry id returns definition id", () {
      final pageEntry = PageEntry.definition(
        definition: EntryDefinition(
          id: "entry-123",
          name: "Test Entry",
          blueprint: EntryBlueprint(
            id: "blueprint-id",
            name: "Test",
            description: "",
            extension: "TestExt",
            dataBlueprint: ObjectBlueprint(fields: {}),
          ),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 100),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: const [],
        ),
      );
      expect(pageEntry.id, "entry-123");
    });

    test("ReferencePageEntry id returns reference id", () {
      const pageEntry = PageEntry.reference(
        id: "ref-456",
        name: "Referenced Entry",
        blueprint: EntryBlueprint(
          id: "blueprint-id",
          name: "Test",
          description: "",
          extension: "TestExt",
          dataBlueprint: ObjectBlueprint(fields: {}),
        ),
        pageId: "page-1",
      );
      expect(pageEntry.id, "ref-456");
    });

    test("NonexistentPageEntry id returns entry id", () {
      const pageEntry = PageEntry.nonexistent(id: "missing-789");
      expect(pageEntry.id, "missing-789");
    });

    test("NoBlueprintPageEntry id returns entry id", () {
      const pageEntry = PageEntry.noBlueprint(
        id: "no-bp-101",
        name: "No Blueprint Entry",
        placement: EntryPlacement(x: 0, y: 0, width: 100, height: 100),
        inwardEdges: [],
        outwardEdges: [],
      );
      expect(pageEntry.id, "no-bp-101");
    });
  });
}
