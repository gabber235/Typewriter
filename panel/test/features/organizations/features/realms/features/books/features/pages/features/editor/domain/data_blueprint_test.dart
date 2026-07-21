import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("PrimitiveBlueprint defaultValue", () {
    test("string defaults to empty string", () {
      final blueprint = DataBlueprint.string();
      expect(blueprint.defaultValue(), "");
    });

    test("string with custom default uses provided value", () {
      final blueprint = DataBlueprint.string(defaultValue: "hello");
      expect(blueprint.defaultValue(), "hello");
    });

    test("integer defaults to 0", () {
      final blueprint = DataBlueprint.integer();
      expect(blueprint.defaultValue(), 0);
    });

    test("integer with custom default uses provided value", () {
      final blueprint = DataBlueprint.integer(defaultValue: 42);
      expect(blueprint.defaultValue(), 42);
    });

    test("decimal defaults to 0.0", () {
      final blueprint = DataBlueprint.decimal();
      expect(blueprint.defaultValue(), 0.0);
    });

    test("decimal with custom default uses provided value", () {
      final blueprint = DataBlueprint.decimal(defaultValue: 3.14);
      expect(blueprint.defaultValue(), 3.14);
    });

    test("boolean defaults to false", () {
      final blueprint = DataBlueprint.boolean();
      expect(blueprint.defaultValue(), false);
    });

    test("boolean with custom default uses provided value", () {
      final blueprint = DataBlueprint.boolean(defaultValue: true);
      expect(blueprint.defaultValue(), true);
    });
  });

  group("EnumBlueprint defaultValue", () {
    test("defaults to first value", () {
      final blueprint = DataBlueprint.enumBlueprint(
        values: ["option1", "option2", "option3"],
      );
      expect(blueprint.defaultValue(), "option1");
    });

    test("uses provided default if valid", () {
      final blueprint = DataBlueprint.enumBlueprint(
        values: ["option1", "option2", "option3"],
        internalDefaultValue: "option2",
      );
      expect(blueprint.defaultValue(), "option2");
    });

    test("falls back to first if provided default is invalid", () {
      final blueprint = DataBlueprint.enumBlueprint(
        values: ["option1", "option2"],
        internalDefaultValue: "invalid",
      );
      expect(blueprint.defaultValue(), "option1");
    });
  });

  group("ListBlueprint defaultValue", () {
    test("defaults to empty list", () {
      final blueprint = DataBlueprint.list(type: DataBlueprint.string());
      expect(blueprint.defaultValue(), <dynamic>[]);
    });

    test("uses provided default if it is a list", () {
      final blueprint = DataBlueprint.list(
        type: DataBlueprint.string(),
        internalDefaultValue: ["a", "b"],
      );
      expect(blueprint.defaultValue(), ["a", "b"]);
    });

    test("falls back to empty list for invalid default", () {
      final blueprint = DataBlueprint.list(
        type: DataBlueprint.string(),
        internalDefaultValue: "not a list",
      );
      expect(blueprint.defaultValue(), <dynamic>[]);
    });
  });

  group("MapBlueprint defaultValue", () {
    test("defaults to empty map", () {
      final blueprint = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.integer(),
      );
      expect(blueprint.defaultValue(), <dynamic, dynamic>{});
    });

    test("uses provided default if it is a map", () {
      final blueprint = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.integer(),
        internalDefaultValue: {"key": 1},
      );
      expect(blueprint.defaultValue(), {"key": 1});
    });
  });

  group("ObjectBlueprint defaultValue", () {
    test("creates object with defaults for all fields", () {
      final blueprint = DataBlueprint.object(
        fields: {
          "name": DataBlueprint.string(defaultValue: "default_name"),
          "count": DataBlueprint.integer(defaultValue: 10),
        },
      );
      expect(blueprint.defaultValue(), {"name": "default_name", "count": 10});
    });

    test("uses provided default if it is a map", () {
      final blueprint = DataBlueprint.object(
        fields: {"name": DataBlueprint.string()},
        internalDefaultValue: {"name": "override"},
      );
      expect(blueprint.defaultValue(), {"name": "override"});
    });

    test("handles nested objects", () {
      final blueprint = DataBlueprint.object(
        fields: {
          "user": DataBlueprint.object(
            fields: {
              "email": DataBlueprint.string(defaultValue: "test@example.com"),
            },
          ),
        },
      );
      expect(blueprint.defaultValue(), {
        "user": {"email": "test@example.com"},
      });
    });
  });

  group("AlgebraicBlueprint defaultValue", () {
    test("defaults to first case with its default value", () {
      final blueprint = DataBlueprint.algebraic(
        cases: {
          "string": DataBlueprint.string(defaultValue: "text"),
          "number": DataBlueprint.integer(defaultValue: 0),
        },
      );
      expect(blueprint.defaultValue(), {"case": "string", "value": "text"});
    });
  });

  group("DataBlueprint matches", () {
    test("primitives of same type match", () {
      final string1 = DataBlueprint.string();
      final string2 = DataBlueprint.string();
      expect(string1.matches(string2), isTrue);
    });

    test("primitives of different types do not match", () {
      final string = DataBlueprint.string();
      final integer = DataBlueprint.integer();
      expect(string.matches(integer), isFalse);
    });

    test("enums with same values match", () {
      final enum1 = DataBlueprint.enumBlueprint(values: ["a", "b"]);
      final enum2 = DataBlueprint.enumBlueprint(values: ["a", "b"]);
      expect(enum1.matches(enum2), isTrue);
    });

    test("enums with different values do not match", () {
      final enum1 = DataBlueprint.enumBlueprint(values: ["a", "b"]);
      final enum2 = DataBlueprint.enumBlueprint(values: ["x", "y"]);
      expect(enum1.matches(enum2), isFalse);
    });

    test("lists with matching element types match", () {
      final list1 = DataBlueprint.list(type: DataBlueprint.string());
      final list2 = DataBlueprint.list(type: DataBlueprint.string());
      expect(list1.matches(list2), isTrue);
    });

    test("lists with different element types do not match", () {
      final list1 = DataBlueprint.list(type: DataBlueprint.string());
      final list2 = DataBlueprint.list(type: DataBlueprint.integer());
      expect(list1.matches(list2), isFalse);
    });

    test("maps with matching key and value types match", () {
      final map1 = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.integer(),
      );
      final map2 = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.integer(),
      );
      expect(map1.matches(map2), isTrue);
    });

    test("maps with different value types do not match", () {
      final map1 = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.integer(),
      );
      final map2 = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.string(),
      );
      expect(map1.matches(map2), isFalse);
    });

    test("objects with same fields match", () {
      final obj1 = DataBlueprint.object(
        fields: {
          "name": DataBlueprint.string(),
          "age": DataBlueprint.integer(),
        },
      );
      final obj2 = DataBlueprint.object(
        fields: {
          "name": DataBlueprint.string(),
          "age": DataBlueprint.integer(),
        },
      );
      expect(obj1.matches(obj2), isTrue);
    });

    test("objects with different field names do not match", () {
      final obj1 = DataBlueprint.object(
        fields: {"name": DataBlueprint.string()},
      );
      final obj2 = DataBlueprint.object(
        fields: {"title": DataBlueprint.string()},
      );
      expect(obj1.matches(obj2), isFalse);
    });

    test("objects with different field types do not match", () {
      final obj1 = DataBlueprint.object(
        fields: {"value": DataBlueprint.string()},
      );
      final obj2 = DataBlueprint.object(
        fields: {"value": DataBlueprint.integer()},
      );
      expect(obj1.matches(obj2), isFalse);
    });

    test("different blueprint kinds do not match", () {
      final string = DataBlueprint.string();
      final list = DataBlueprint.list(type: DataBlueprint.string());
      expect(string.matches(list), isFalse);
    });
  });

  group("DataBlueprint modifiers", () {
    test("hasModifier returns true when modifier present", () {
      final blueprint = DataBlueprint.string(
        modifiers: [const Modifier.readOnly()],
      );
      expect(blueprint.hasModifier<ReadOnlyModifier>(), isTrue);
    });

    test("hasModifier returns false when modifier absent", () {
      final blueprint = DataBlueprint.string();
      expect(blueprint.hasModifier<ReadOnlyModifier>(), isFalse);
    });

    test("getModifiers returns all matching modifiers", () {
      final blueprint = DataBlueprint.string(
        modifiers: [
          const Modifier.readOnly(),
          const Modifier.multiline(),
          const Modifier.readOnly(recursive: false),
        ],
      );
      final readOnlyModifiers = blueprint.getModifiers<ReadOnlyModifier>();
      expect(readOnlyModifiers.length, 2);
    });

    test("getModifiers returns empty for no matches", () {
      final blueprint = DataBlueprint.string(
        modifiers: [const Modifier.multiline()],
      );
      final readOnlyModifiers = blueprint.getModifiers<ReadOnlyModifier>();
      expect(readOnlyModifiers, isEmpty);
    });
  });

  group("DataBlueprint hasCustomLayout", () {
    test("object has custom layout", () {
      final blueprint = DataBlueprint.object(fields: {});
      expect(blueprint.hasCustomLayout, isTrue);
    });

    test("list has custom layout", () {
      final blueprint = DataBlueprint.list(type: DataBlueprint.string());
      expect(blueprint.hasCustomLayout, isTrue);
    });

    test("map has custom layout", () {
      final blueprint = DataBlueprint.map(
        key: DataBlueprint.string(),
        value: DataBlueprint.string(),
      );
      expect(blueprint.hasCustomLayout, isTrue);
    });

    test("primitive does not have custom layout", () {
      final blueprint = DataBlueprint.string();
      expect(blueprint.hasCustomLayout, isFalse);
    });

    test("enum does not have custom layout", () {
      final blueprint = DataBlueprint.enumBlueprint(values: ["a", "b"]);
      expect(blueprint.hasCustomLayout, isFalse);
    });
  });

  group("PrimitiveType validation", () {
    test("boolean validates booleans", () {
      expect(PrimitiveType.boolean.validate(true), isTrue);
      expect(PrimitiveType.boolean.validate(false), isTrue);
      expect(PrimitiveType.boolean.validate("true"), isFalse);
      expect(PrimitiveType.boolean.validate(1), isFalse);
    });

    test("double validates doubles", () {
      expect(PrimitiveType.double.validate(3.14), isTrue);
      expect(PrimitiveType.double.validate(0.0), isTrue);
      expect(PrimitiveType.double.validate(42), isFalse);
      expect(PrimitiveType.double.validate("3.14"), isFalse);
    });

    test("integer validates integers", () {
      expect(PrimitiveType.integer.validate(42), isTrue);
      expect(PrimitiveType.integer.validate(0), isTrue);
      expect(PrimitiveType.integer.validate(3.14), isFalse);
      expect(PrimitiveType.integer.validate("42"), isFalse);
    });

    test("string validates strings", () {
      expect(PrimitiveType.string.validate("hello"), isTrue);
      expect(PrimitiveType.string.validate(""), isTrue);
      expect(PrimitiveType.string.validate(42), isFalse);
      expect(PrimitiveType.string.validate(null), isFalse);
    });
  });

  group("Blueprint list overlap", () {
    test("single blueprint returns itself", () {
      final blueprints = [DataBlueprint.string()];
      expect(blueprints.overlap, isNotNull);
      expect(blueprints.overlap is PrimitiveBlueprint, isTrue);
    });

    test("empty list returns null", () {
      final blueprints = <DataBlueprint>[];
      expect(blueprints.overlap, isNull);
    });

    test("matching primitives return overlap", () {
      final blueprints = [DataBlueprint.string(), DataBlueprint.string()];
      expect(blueprints.overlap, isNotNull);
    });

    test("different primitives return null", () {
      final blueprints = [DataBlueprint.string(), DataBlueprint.integer()];
      expect(blueprints.overlap, isNull);
    });

    test("objects with common fields return overlap with those fields", () {
      final obj1 = DataBlueprint.object(
        fields: {
          "shared": DataBlueprint.string(),
          "unique1": DataBlueprint.integer(),
        },
      );
      final obj2 = DataBlueprint.object(
        fields: {
          "shared": DataBlueprint.string(),
          "unique2": DataBlueprint.boolean(),
        },
      );
      final overlap = [obj1, obj2].overlap;
      expect(overlap, isNotNull);
      expect(overlap is ObjectBlueprint, isTrue);
      final objectOverlap = overlap! as ObjectBlueprint;
      expect(objectOverlap.fields.containsKey("shared"), isTrue);
      expect(objectOverlap.fields.containsKey("unique1"), isFalse);
      expect(objectOverlap.fields.containsKey("unique2"), isFalse);
    });

    test("objects with no common fields return null", () {
      final obj1 = DataBlueprint.object(fields: {"a": DataBlueprint.string()});
      final obj2 = DataBlueprint.object(fields: {"b": DataBlueprint.string()});
      final overlap = [obj1, obj2].overlap;
      expect(overlap, isNull);
    });

    test("lists with matching element types return overlap", () {
      final list1 = DataBlueprint.list(type: DataBlueprint.string());
      final list2 = DataBlueprint.list(type: DataBlueprint.string());
      final overlap = [list1, list2].overlap;
      expect(overlap, isNotNull);
      expect(overlap is ListBlueprint, isTrue);
    });
  });
}
