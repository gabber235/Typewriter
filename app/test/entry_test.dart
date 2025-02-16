import "package:flutter_test/flutter_test.dart";
import "package:typewriter/models/entry.dart";

void main() {
  final rawDynamicEntry = {
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

  group("Get field from entry", () {
    test("When a entry is parsed expect its fields to be able to be fetched",
        () {
      final entry = Entry(rawDynamicEntry);

      expect(entry.id, "1");
      expect(entry.name, "test");
      expect(entry.blueprintId, "test_blueprint_id");

      expect(entry.get("simple_list"), [1, 2, 3]);
      expect(entry.get("simple_list.1"), 2);

      expect(entry.get("complex_list"), [
        {"id": "1", "name": "test1"},
        {"id": "2", "name": "test2"},
        {"id": "3", "name": "test3"},
      ]);
      expect(entry.get("complex_list.1.name"), "test2");

      expect(entry.get("simple_map"), {"key1": "value1", "key2": "value2"});
      expect(entry.get("simple_map.key1"), "value1");

      expect(entry.get("complex_map.key2.inner_list.1.name"), "test_b");
    });

    test("When a key is not found, null is returned", () {
      final entry = Entry(rawDynamicEntry);
      expect(entry.get("not_found"), null);
      expect(entry.get("simple_list.4"), null);
      expect(entry.get("complex_list.4.name"), null);
      expect(entry.get("complex_list.1.not_found"), null);
      expect(entry.get("simple_map.key3"), null);
    });

    test("When a key is not found, a default value is returned", () {
      final entry = Entry(rawDynamicEntry);
      expect(entry.get("not_found", "default"), "default");
      expect(entry.get("simple_list.4", "default"), "default");
      expect(entry.get("complex_list.4.name", "default"), "default");
      expect(entry.get("complex_list.1.not_found", "default"), "default");
      expect(entry.get("simple_map.key3", "default"), "default");
    });
  });

  group("Get all fields from entry", () {
    test("When a path is fetched, all values should be returned", () {
      final entry = Entry(rawDynamicEntry);
      expect(entry.getAll("simple_list.*"), [1, 2, 3]);
      expect(entry.getAll("simple_map.*"), ["value1", "value2"]);
      expect(entry.getAll("complex_map.*.name"), ["test1", "test2"]);
      expect(
        entry.getAll("complex_map.*.inner_list.*.name"),
        ["test1", "test2", "test3", "test_a", "test_b", "test_c"],
      );
      expect(
        entry.getAll("complex_map.key2.inner_list.*.name"),
        ["test_a", "test_b", "test_c"],
      );
    });
  });

  group("Copy entry with new value", () {
    test("When a dynamic entry is updated, the new value is returned", () {
      final entry = Entry(rawDynamicEntry);
      var newEntry = entry.copyWith("simple_list.1", 4);
      expect(newEntry.get("simple_list.1"), 4);

      newEntry = entry.copyWith("complex_list.1.name", "new_name");
      expect(newEntry.get("complex_list.1.name"), "new_name");

      newEntry = entry.copyWith("simple_map.key1", "new_value");
      expect(newEntry.get("simple_map.key1"), "new_value");

      newEntry =
          entry.copyWith("complex_map.key2.inner_list.1.name", "new_name");
      expect(newEntry.get("complex_map.key2.inner_list.1.name"), "new_name");
    });

    test("When an list is updated, expect the new list to be returned", () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyWith("simple_list", [4, 5, 6]);
      expect(newEntry.get("simple_list"), [4, 5, 6]);
    });

    test("When an map is updated, expect the new map to be returned", () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry
          .copyWith("simple_map", {"key1": "new_value", "key2": "new_value"});
      expect(newEntry.get("simple_map"), {
        "key1": "new_value",
        "key2": "new_value",
      });
    });

    test("When an entry is updated, expect the original entry to be unchanged",
        () {
      final entry = Entry(rawDynamicEntry);
      // ignore: cascade_invocations
      entry.copyWith("complex_map.key2.inner_list.1.name", "new_name");
      expect(entry.get("complex_map.key2.inner_list.1.name"), "test_b");
    });

    test(
        "When an entry is updated with a non-existent path, expect the path to be created",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyWith("new_path.1.something", "new_value");
      expect(newEntry.get("new_path.1.something"), "new_value");
    });

    test(
        "When an entry is updated with a non-existent path with wildcard, expect nothing to happen",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyWith("new_path.*.something", "new_value");
      expect(newEntry.get("new_path.*.something"), null);
    });

    test(
        "When an entry is updated with a existing null value in the list, expect a correct string to be set",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyWith("null_list.0", "new_value");
      expect(newEntry.get("null_list.0"), "new_value");
    });
    test(
        "When an entry is updated with a existing null value in the list, expect a correct data value to be set",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyWith("null_list.0.something", "new_value");
      expect(newEntry.get("null_list.0.something"), "new_value");
    });
  });

  group("Copy Mapped", () {
    test(
        "When copying while modifying simple static field expect the field to change",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyMapped("simple_list.1", (value) => value + 1);

      expect(
        newEntry.get("simple_list.0"),
        1,
        reason: "simple_list.0 should not have changed",
      );
      expect(
        newEntry.get("simple_list.1"),
        3,
        reason: "simple_list.1 should have changed",
      );
      expect(
        newEntry.get("simple_list.2"),
        3,
        reason: "simple_list.2 should not have changed",
      );
    });

    test(
        "When copying while modifying complex static field expect the field to change",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry =
          entry.copyMapped("complex_list.1.name", (value) => value + "_new");

      expect(
        newEntry.get("complex_list.0.name"),
        "test1",
        reason: "complex_list.0.name should not have changed",
      );
      expect(
        newEntry.get("complex_list.1.name"),
        "test2_new",
        reason: "complex_list.1.name should have changed",
      );
      expect(
        newEntry.get("complex_list.2.name"),
        "test3",
        reason: "complex_list.2.name should not have changed",
      );
    });

    test(
        "When copying while modifying simple dynamic field expect the field to change",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry =
          entry.copyMapped("simple_map.*", (value) => value + "_new");

      expect(
        newEntry.get("simple_map.key1"),
        "value1_new",
        reason: "simple_map.key1 should have changed",
      );
      expect(
        newEntry.get("simple_map.key2"),
        "value2_new",
        reason: "simple_map.key2 should have changed",
      );
    });

    test(
        "When copying while modifying complex dynamic field expect the field to change",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry =
          entry.copyMapped("complex_map.*.name", (value) => value + "_new");

      expect(
        newEntry.get("complex_map.key1.name"),
        "test1_new",
        reason: "complex_map.key1.name should have changed",
      );
      expect(
        newEntry.get("complex_map.key2.name"),
        "test2_new",
        reason: "complex_map.key2.name should have changed",
      );
    });

    test(
        "When copying while modifying fields with multiple *'s and a final field expect the fields to change",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyMapped(
        "complex_map.*.inner_list.*.name",
        (value) => value + "_new",
      );

      expect(newEntry.get("complex_map.key1.inner_list.0.name"), "test1_new");
      expect(newEntry.get("complex_map.key1.inner_list.1.name"), "test2_new");
      expect(newEntry.get("complex_map.key1.inner_list.2.name"), "test3_new");
      expect(newEntry.get("complex_map.key2.inner_list.0.name"), "test_a_new");
      expect(newEntry.get("complex_map.key2.inner_list.1.name"), "test_b_new");
      expect(newEntry.get("complex_map.key2.inner_list.2.name"), "test_c_new");
    });

    test(
        "When copying while modifying simple dynamic field to null expect the field to be removed",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyMapped(
        "simple_list.*",
        (value) => value == 2 ? null : value,
      );

      expect(
        newEntry.get("simple_list"),
        [1, 3],
        reason: "Should have removed the value of 2",
      );
    });

    test(
        "When copying while modifying complex dynamic field to null expect the field to be removed",
        () {
      final entry = Entry(rawDynamicEntry);
      final newEntry = entry.copyMapped(
        "complex_map.*.inner_list.*",
        (value) => ["test1", "test2"].contains(value["name"]) ? null : value,
      );

      expect(newEntry.get("complex_map.key1.inner_list"), [
        {"id": "3", "name": "test3"},
      ]);
      expect(newEntry.get("complex_map.key2.inner_list"), [
        {"id": "1", "name": "test_a"},
        {"id": "2", "name": "test_b"},
        {"id": "3", "name": "test_c"},
      ]);
    });
  });

  group("New Paths", () {
    test("Static path returns only that path", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("simple_map.key1");

      expect(paths, ["simple_map.key1"]);
    });
    test("Static non-existing path returns path", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("non_existing");

      expect(paths, ["non_existing"]);
    });
    test("Simple list returns path with next index", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("simple_list.*");

      expect(paths, ["simple_list.3"]);
    });
    test("Complex list with fixed ending returns all paths", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("complex_list.*.name");

      expect(paths, [
        "complex_list.0.name",
        "complex_list.1.name",
        "complex_list.2.name",
      ]);
    });
    test("Simple map with wildcard ending returns all paths", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("simple_map.*");

      expect(paths, ["simple_map.key1", "simple_map.key2"]);
    });
    test("Complex map with ending list returns next index", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("complex_map.*.inner_list.*");

      expect(paths, [
        "complex_map.key1.inner_list.3",
        "complex_map.key2.inner_list.3",
      ]);
    });
    test("Multi wildcard path with fixed ending returns all paths", () {
      final entry = Entry(rawDynamicEntry);
      final paths = entry.newPaths("complex_map.*.inner_list.*.name");

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
}
