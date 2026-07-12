import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";

void main() {
  final rawDynamicData = {
    "id": "1",
    "name": "test",
    "type": "test_blueprint_id",
    "simple_list": [1, 2, 3],
    "complex_list": [
      {"id": "1", "name": "test1"},
      {"id": "2", "name": "test2"},
      {"id": "3", "name": "test3"},
    ],
    "simple_map": {"key1": "value1", "key2": "value2"},
    "complex_map": {
      "key1": {
        "id": "1",
        "name": "test1",
        "inner_list": [
          {"id": "1", "name": "test1"},
          {"id": "2", "name": "test2"},
          {"id": "3", "name": "test3"},
        ],
      },
      "key2": {
        "id": "2",
        "name": "test2",
        "inner_list": [
          {"id": "1", "name": "test_a"},
          {"id": "2", "name": "test_b"},
          {"id": "3", "name": "test_c"},
        ],
      },
    },
    "null_list": [null],
  };

  group("Get field from dynamicData", () {
    test(
      "When a dynamicData is parsed expect its fields to be able to be fetched",
      () {
        final dynamicData = DynamicData(rawDynamicData);

        expect(dynamicData.get("simple_list"), [1, 2, 3]);
        expect(dynamicData.get("simple_list.1"), 2);

        expect(dynamicData.get("complex_list"), [
          {"id": "1", "name": "test1"},
          {"id": "2", "name": "test2"},
          {"id": "3", "name": "test3"},
        ]);
        expect(dynamicData.get("complex_list.1.name"), "test2");

        expect(dynamicData.get("simple_map"), {
          "key1": "value1",
          "key2": "value2",
        });
        expect(dynamicData.get("simple_map.key1"), "value1");

        expect(dynamicData.get("complex_map.key2.inner_list.1.name"), "test_b");
      },
    );

    test("When a key is not found, null is returned", () {
      final dynamicData = DynamicData(rawDynamicData);
      expect(dynamicData.get("not_found"), null);
      expect(dynamicData.get("simple_list.4"), null);
      expect(dynamicData.get("complex_list.4.name"), null);
      expect(dynamicData.get("complex_list.1.not_found"), null);
      expect(dynamicData.get("simple_map.key3"), null);
    });

    test("When a key is not found, a default value is returned", () {
      final dynamicData = DynamicData(rawDynamicData);
      expect(dynamicData.get("not_found", "default"), "default");
      expect(dynamicData.get("simple_list.4", "default"), "default");
      expect(dynamicData.get("complex_list.4.name", "default"), "default");
      expect(dynamicData.get("complex_list.1.not_found", "default"), "default");
      expect(dynamicData.get("simple_map.key3", "default"), "default");
    });
  });

  group("Get all fields from dynamicData", () {
    test("When a path is fetched, all values should be returned", () {
      final dynamicData = DynamicData(rawDynamicData);
      expect(dynamicData.getAll("simple_list.*"), [1, 2, 3]);
      expect(dynamicData.getAll("simple_map.*"), ["value1", "value2"]);
      expect(dynamicData.getAll("complex_map.*.name"), ["test1", "test2"]);
      expect(dynamicData.getAll("complex_map.*.inner_list.*.name"), [
        "test1",
        "test2",
        "test3",
        "test_a",
        "test_b",
        "test_c",
      ]);
      expect(dynamicData.getAll("complex_map.key2.inner_list.*.name"), [
        "test_a",
        "test_b",
        "test_c",
      ]);
    });
  });

  group("Copy dynamicData with new value", () {
    test(
      "When a dynamic dynamicData is updated, the new value is returned",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        var newDynamicData = dynamicData.copyWith("simple_list.1", 4);
        expect(newDynamicData.get("simple_list.1"), 4);

        newDynamicData = dynamicData.copyWith(
          "complex_list.1.name",
          "new_name",
        );
        expect(newDynamicData.get("complex_list.1.name"), "new_name");

        newDynamicData = dynamicData.copyWith("simple_map.key1", "new_value");
        expect(newDynamicData.get("simple_map.key1"), "new_value");

        newDynamicData = dynamicData.copyWith(
          "complex_map.key2.inner_list.1.name",
          "new_name",
        );
        expect(
          newDynamicData.get("complex_map.key2.inner_list.1.name"),
          "new_name",
        );
      },
    );

    test("When an list is updated, expect the new list to be returned", () {
      final dynamicData = DynamicData(rawDynamicData);
      final newDynamicData = dynamicData.copyWith("simple_list", [4, 5, 6]);
      expect(newDynamicData.get("simple_list"), [4, 5, 6]);
    });

    test("When an map is updated, expect the new map to be returned", () {
      final dynamicData = DynamicData(rawDynamicData);
      final newDynamicData = dynamicData.copyWith("simple_map", {
        "key1": "new_value",
        "key2": "new_value",
      });
      expect(newDynamicData.get("simple_map"), {
        "key1": "new_value",
        "key2": "new_value",
      });
    });

    test(
      "When an dynamicData is updated, expect the original entry to be unchanged",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        // ignore: cascade_invocations
        dynamicData.copyWith("complex_map.key2.inner_list.1.name", "new_name");
        expect(dynamicData.get("complex_map.key2.inner_list.1.name"), "test_b");
      },
    );

    test(
      "When an dynamicData is updated with a non-existent path, expect the path to be created",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyWith(
          "new_path.1.something",
          "new_value",
        );
        expect(newDynamicData.get("new_path.1.something"), "new_value");
      },
    );

    test(
      "When an dynamicData is updated with a non-existent path with wildcard, expect nothing to happen",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyWith(
          "new_path.*.something",
          "new_value",
        );
        expect(newDynamicData.get("new_path.*.something"), null);
      },
    );

    test(
      "When an dynamicData is updated with a existing null value in the list, expect a correct string to be set",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyWith("null_list.0", "new_value");
        expect(newDynamicData.get("null_list.0"), "new_value");
      },
    );
    test(
      "When an dynamicData is updated with a existing null value in the list, expect a correct data value to be set",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyWith(
          "null_list.0.something",
          "new_value",
        );
        expect(newDynamicData.get("null_list.0.something"), "new_value");
      },
    );
  });

  group("Copy Mapped", () {
    test(
      "When copying while modifying simple static field expect the field to change",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "simple_list.1",
          (value) => value + 1,
        );

        expect(
          newDynamicData.get("simple_list.0"),
          1,
          reason: "simple_list.0 should not have changed",
        );
        expect(
          newDynamicData.get("simple_list.1"),
          3,
          reason: "simple_list.1 should have changed",
        );
        expect(
          newDynamicData.get("simple_list.2"),
          3,
          reason: "simple_list.2 should not have changed",
        );
      },
    );

    test(
      "When copying while modifying complex static field expect the field to change",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "complex_list.1.name",
          (value) => value + "_new",
        );

        expect(
          newDynamicData.get("complex_list.0.name"),
          "test1",
          reason: "complex_list.0.name should not have changed",
        );
        expect(
          newDynamicData.get("complex_list.1.name"),
          "test2_new",
          reason: "complex_list.1.name should have changed",
        );
        expect(
          newDynamicData.get("complex_list.2.name"),
          "test3",
          reason: "complex_list.2.name should not have changed",
        );
      },
    );

    test(
      "When copying while modifying simple dynamic field expect the field to change",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "simple_map.*",
          (value) => value + "_new",
        );

        expect(
          newDynamicData.get("simple_map.key1"),
          "value1_new",
          reason: "simple_map.key1 should have changed",
        );
        expect(
          newDynamicData.get("simple_map.key2"),
          "value2_new",
          reason: "simple_map.key2 should have changed",
        );
      },
    );

    test(
      "When copying while modifying complex dynamic field expect the field to change",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "complex_map.*.name",
          (value) => value + "_new",
        );

        expect(
          newDynamicData.get("complex_map.key1.name"),
          "test1_new",
          reason: "complex_map.key1.name should have changed",
        );
        expect(
          newDynamicData.get("complex_map.key2.name"),
          "test2_new",
          reason: "complex_map.key2.name should have changed",
        );
      },
    );

    test(
      "When copying while modifying fields with multiple *'s and a final field expect the fields to change",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "complex_map.*.inner_list.*.name",
          (value) => value + "_new",
        );

        expect(
          newDynamicData.get("complex_map.key1.inner_list.0.name"),
          "test1_new",
        );
        expect(
          newDynamicData.get("complex_map.key1.inner_list.1.name"),
          "test2_new",
        );
        expect(
          newDynamicData.get("complex_map.key1.inner_list.2.name"),
          "test3_new",
        );
        expect(
          newDynamicData.get("complex_map.key2.inner_list.0.name"),
          "test_a_new",
        );
        expect(
          newDynamicData.get("complex_map.key2.inner_list.1.name"),
          "test_b_new",
        );
        expect(
          newDynamicData.get("complex_map.key2.inner_list.2.name"),
          "test_c_new",
        );
      },
    );

    test(
      "When copying while modifying simple dynamic field to null expect the field to be removed",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "simple_list.*",
          (value) => value == 2 ? null : value,
        );

        expect(newDynamicData.get("simple_list"), [
          1,
          3,
        ], reason: "Should have removed the value of 2");
      },
    );

    test(
      "When copying while modifying complex dynamic field to null expect the field to be removed",
      () {
        final dynamicData = DynamicData(rawDynamicData);
        final newDynamicData = dynamicData.copyMapped(
          "complex_map.*.inner_list.*",
          (value) => ["test1", "test2"].contains(value["name"]) ? null : value,
        );

        expect(newDynamicData.get("complex_map.key1.inner_list"), [
          {"id": "3", "name": "test3"},
        ]);
        expect(newDynamicData.get("complex_map.key2.inner_list"), [
          {"id": "1", "name": "test_a"},
          {"id": "2", "name": "test_b"},
          {"id": "3", "name": "test_c"},
        ]);
      },
    );
  });

  group("New Paths", () {
    test("Static path returns only that path", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("simple_map.key1");

      expect(paths, ["simple_map.key1"]);
    });
    test("Static non-existing path returns path", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("non_existing");

      expect(paths, ["non_existing"]);
    });
    test("Simple list returns path with next index", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("simple_list.*");

      expect(paths, ["simple_list.3"]);
    });
    test("Complex list with fixed ending returns all paths", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("complex_list.*.name");

      expect(paths, [
        "complex_list.0.name",
        "complex_list.1.name",
        "complex_list.2.name",
      ]);
    });
    test("Simple map with wildcard ending returns all paths", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("simple_map.*");

      expect(paths, ["simple_map.key1", "simple_map.key2"]);
    });
    test("Complex map with ending list returns next index", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("complex_map.*.inner_list.*");

      expect(paths, [
        "complex_map.key1.inner_list.3",
        "complex_map.key2.inner_list.3",
      ]);
    });
    test("Multi wildcard path with fixed ending returns all paths", () {
      final dynamicData = DynamicData(rawDynamicData);
      final paths = dynamicData.newPaths("complex_map.*.inner_list.*.name");

      expect(paths, [
        "complex_map.key1.inner_list.0.name",
        "complex_map.key1.inner_list.1.name",
        "complex_map.key1.inner_list.2.name",
        "complex_map.key2.inner_list.0.name",
        "complex_map.key2.inner_list.1.name",
        "complex_map.key2.inner_list.2.name",
      ]);
    });
  });

  group("Edge Cases - Empty Collections", () {
    test("get returns null for path in empty map", () {
      final dynamicData = DynamicData({});
      expect(dynamicData.get("any.path"), null);
    });

    test("getAll returns empty list for path in empty map", () {
      final dynamicData = DynamicData({});
      expect(dynamicData.getAll("any.path"), <dynamic>[]);
    });

    test("copyWith on empty map creates path", () {
      final dynamicData = DynamicData({});
      final newData = dynamicData.copyWith("new.nested.path", "value");
      expect(newData.get("new.nested.path"), "value");
    });

    test("copyMapped on empty map returns unchanged", () {
      final dynamicData = DynamicData({});
      final newData = dynamicData.copyMapped("any.*", (v) => v);
      expect(newData.data, <String, dynamic>{});
    });

    test("get on empty list at root returns null", () {
      final dynamicData = DynamicData({"list": <dynamic>[]});
      expect(dynamicData.get("list.0"), null);
      expect(dynamicData.get("list.*"), null);
    });

    test("getAll on empty list returns empty list", () {
      final dynamicData = DynamicData({"list": <dynamic>[]});
      expect(dynamicData.getAll("list.*"), <dynamic>[]);
    });
  });

  group("Edge Cases - Deeply Nested Paths", () {
    test("get works with 6 levels of nesting", () {
      final dynamicData = DynamicData({
        "a": {
          "b": {
            "c": {
              "d": {
                "e": {"f": "deep_value"},
              },
            },
          },
        },
      });
      expect(dynamicData.get("a.b.c.d.e.f"), "deep_value");
    });

    test("copyWith works with 6 levels of nesting", () {
      final dynamicData = DynamicData({
        "a": {
          "b": {
            "c": {
              "d": {
                "e": {"f": "old_value"},
              },
            },
          },
        },
      });
      final newData = dynamicData.copyWith("a.b.c.d.e.f", "new_value");
      expect(newData.get("a.b.c.d.e.f"), "new_value");
    });

    test("mixed list and map nesting 5 levels", () {
      final dynamicData = DynamicData({
        "users": [
          {
            "profile": {
              "settings": [
                {"theme": "dark"},
              ],
            },
          },
        ],
      });
      expect(dynamicData.get("users.0.profile.settings.0.theme"), "dark");
    });
  });

  group("Edge Cases - Type Mismatches", () {
    test("accessing map key on primitive returns null", () {
      final dynamicData = DynamicData({"value": "string"});
      expect(dynamicData.get("value.nested"), null);
    });

    test("accessing list index on primitive returns null", () {
      final dynamicData = DynamicData({"value": 42});
      expect(dynamicData.get("value.0"), null);
    });

    test("accessing map key on list returns null", () {
      final dynamicData = DynamicData({
        "list": [1, 2, 3],
      });
      expect(dynamicData.get("list.key"), null);
    });

    test("accessing negative index returns null", () {
      final dynamicData = DynamicData({
        "list": [1, 2, 3],
      });
      expect(dynamicData.get("list.-1"), null);
    });

    test("accessing out of bounds index returns null", () {
      final dynamicData = DynamicData({
        "list": [1, 2, 3],
      });
      expect(dynamicData.get("list.99"), null);
    });
  });

  group("Edge Cases - Special Keys", () {
    test("empty string path returns entire data", () {
      final dynamicData = DynamicData({"key": "value"});
      expect(dynamicData.get(""), {"key": "value"});
    });

    test("numeric string key in map works", () {
      final dynamicData = DynamicData({"123": "numeric_key"});
      expect(dynamicData.get("123"), "numeric_key");
    });

    test("key containing dots when no split needed", () {
      final dynamicData = DynamicData({"simple": "value"});
      expect(dynamicData.get("simple"), "value");
    });

    test("unicode keys work", () {
      final dynamicData = DynamicData({"日本語": "japanese", "emoji": "🎮"});
      expect(dynamicData.get("日本語"), "japanese");
      expect(dynamicData.get("emoji"), "🎮");
    });
  });

  group("Edge Cases - Null Values", () {
    test("get returns null for explicit null value", () {
      final dynamicData = DynamicData({"null_value": null});
      expect(dynamicData.get("null_value"), null);
    });

    test("get with default returns default for null value", () {
      final dynamicData = DynamicData({"null_value": null});
      expect(dynamicData.get("null_value", "default"), "default");
    });

    test("nested path through null value returns null", () {
      final dynamicData = DynamicData({"parent": null});
      expect(dynamicData.get("parent.child"), null);
    });

    test("copyWith replaces null with value", () {
      final dynamicData = DynamicData({"null_value": null});
      final newData = dynamicData.copyWith("null_value", "not_null");
      expect(newData.get("null_value"), "not_null");
    });
  });

  group("Edge Cases - Equality and Immutability", () {
    test("two DynamicData with same content are equal", () {
      final data1 = DynamicData({"a": 1, "b": 2});
      final data2 = DynamicData({"a": 1, "b": 2});
      expect(data1, equals(data2));
    });

    test("copyWith does not modify original", () {
      final original = DynamicData({"value": 1});
      final modified = original.copyWith("value", 2);
      expect(original.get("value"), 1);
      expect(modified.get("value"), 2);
    });

    test("nested copyWith does not modify original nested objects", () {
      final original = DynamicData({
        "nested": {"value": 1},
      });
      final modified = original.copyWith("nested.value", 2);
      expect(original.get("nested.value"), 1);
      expect(modified.get("nested.value"), 2);
    });
  });
}
