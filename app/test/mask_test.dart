import "package:flutter_test/flutter_test.dart";
import "package:typewriter/utils/extensions.dart";

void main() {
  group("Golden path", () {
    test("Mask simple lists", () {
      final list1 = [1, 2];
      final list2 = [3, 4, 5, 6, 7];

      final merged = list1.mask(list2);

      expect(merged, [3, 4, 5, 6, 7]);

      final merged2 = list2.mask(list1);

      expect(merged2, [1, 2, 5, 6, 7]);
    });

    test("Mask simple maps", () {
      final map1 = {"abc": "value1", "def": "value2"};
      final map2 = {"def": "value3", "ghi": "value4"};

      final merged = map1.mask(map2);

      expect(merged, {"abc": "value1", "def": "value3", "ghi": "value4"});

      final merged2 = map2.mask(map1);

      expect(merged2, {"abc": "value1", "def": "value2", "ghi": "value4"});
    });

    test("Mask nested lists", () {
      final list1 = [
        [1, 2],
        [3, 4],
      ];
      final list2 = [
        [5, 6, 7],
        [8],
      ];
      final merged = list1.mask(list2);
      expect(merged, [
        [5, 6, 7],
        [8, 4],
      ]);
      final merged2 = list2.mask(list1);
      expect(merged2, [
        [1, 2, 7],
        [3, 4],
      ]);
    });

    test("Mask nested maps", () {
      final map1 = {
        "abc": {"id": 1, "name": "test1"},
        "def": {"id": 2, "name": "test2", "extra": "value"},
      };
      final map2 = {
        "def": {"id": 3, "name": "test3", "extra2": "value2"},
        "ghi": {"id": 4, "name": "test4"},
      };
      final merged = map1.mask(map2);
      expect(merged, {
        "abc": {"id": 1, "name": "test1"},
        "def": {"id": 3, "name": "test3", "extra": "value", "extra2": "value2"},
        "ghi": {"id": 4, "name": "test4"},
      });
      final merged2 = map2.mask(map1);
      expect(merged2, {
        "abc": {"id": 1, "name": "test1"},
        "def": {"id": 2, "name": "test2", "extra": "value", "extra2": "value2"},
        "ghi": {"id": 4, "name": "test4"},
      });
    });

    test("Mask lists with maps", () {
      final list1 = [
        {"id": 1, "some": "value"},
        {"id": 2, "some": "value"},
      ];
      final list2 = [
        {"id": 3, "other": "test3"},
        {"id": 4, "other": "test4"},
      ];

      final merged = list1.mask(list2);
      expect(merged, [
        {"id": 3, "some": "value", "other": "test3"},
        {"id": 4, "some": "value", "other": "test4"},
      ]);

      final merged2 = list2.mask(list1);
      expect(merged2, [
        {"id": 1, "some": "value", "other": "test3"},
        {"id": 2, "some": "value", "other": "test4"},
      ]);
    });

    test("Mask maps with lists", () {
      final map1 = {
        "abc": [1, 2],
        "def": [3, 4],
        "some": "value",
      };
      final map2 = {
        "abc": [5, 6, 7],
        "def": [8],
        "other": "test3",
      };

      final merged = map1.mask(map2);
      expect(merged, {
        "abc": [5, 6, 7],
        "def": [8, 4],
        "some": "value",
        "other": "test3",
      });

      final merged2 = map2.mask(map1);
      expect(merged2, {
        "abc": [1, 2, 7],
        "def": [3, 4],
        "some": "value",
        "other": "test3",
      });
    });

    test("Mask switching lists and maps", () {
      final list1 = [
        {
          "id": 1,
          "list": [1, 2],
          "map": {"id": 1, "some": "value"},
        },
        {
          "id": 2,
          "list": [3, 4],
          "map": {"id": 2, "some": "value"},
        },
      ];
      final list2 = [
        {
          "id": 3,
          "list": [5, 6, 7],
          "map": {"id": 3, "other": "test3"},
        },
        {
          "id": 4,
          "list": [8],
          "map": {"id": 4, "other": "test4"},
        },
      ];

      final merged = list1.mask(list2);
      expect(merged, [
        {
          "id": 3,
          "list": [5, 6, 7],
          "map": {"id": 3, "some": "value", "other": "test3"},
        },
        {
          "id": 4,
          "list": [8, 4],
          "map": {"id": 4, "some": "value", "other": "test4"},
        },
      ]);

      final merged2 = list2.mask(list1);
      expect(merged2, [
        {
          "id": 1,
          "list": [1, 2, 7],
          "map": {"id": 1, "some": "value", "other": "test3"},
        },
        {
          "id": 2,
          "list": [3, 4],
          "map": {"id": 2, "some": "value", "other": "test4"},
        },
      ]);

    });
    test("Mask null values", () {
      final map1 = {
          "some": "value",
          "list": [1, 2],

      };
      final map2 = {
          "some": null,
          "list": [null],
      };
      final merged = map1.mask(map2);
      expect(merged, {
          "some": "value",
          "list": [1, 2],
      });
      final merged2 = map2.mask(map1);
      expect(merged2, {
          "some": "value",
          "list": [1, 2],
      });
    });

  });

  group("Error cases", () {
    test("Mask map with incompatible types", () {
      final trueMap = {
        "list": [1, 2],
        "map": {"id": 1, "some": "value"},
        "string": "test",
        "int": 1,
      };
      final fakeMap = {"list": "", "map": "", "string": 0, "int": ""};

      final merged = trueMap.mask(fakeMap);
      expect(merged, {
        "list": [1, 2],
        "map": {"id": 1, "some": "value"},
        "string": "test",
        "int": 1,
      });
      final merged2 = fakeMap.mask(trueMap);
      expect(merged2, {
        "list": "",
        "map": "",
        "string": 0,
        "int": "",
      });
    });
  });
}
