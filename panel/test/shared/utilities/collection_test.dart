import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("ListX", () {
    group("randomOrNull", () {
      test("returns null for empty list", () {
        final list = <int>[];
        expect(list.randomOrNull(), isNull);
      });

      test("returns element for non-empty list", () {
        final list = [1, 2, 3];
        final result = list.randomOrNull();
        expect(list, contains(result));
      });

      test("returns single element for singleton list", () {
        final list = [42];
        expect(list.randomOrNull(), 42);
      });
    });

    group("randomElement", () {
      test("throws exception for empty list", () {
        final list = <int>[];
        expect(list.randomElement, throwsException);
      });

      test("returns element for non-empty list", () {
        final list = [1, 2, 3];
        final result = list.randomElement();
        expect(list, contains(result));
      });

      test("returns single element for singleton list", () {
        final list = [42];
        expect(list.randomElement(), 42);
      });
    });

    group("intersection", () {
      test("returns common elements", () {
        final list1 = [1, 2, 3, 4];
        final list2 = [3, 4, 5, 6];
        expect(list1.intersection(list2).toList(), [3, 4]);
      });

      test("returns empty when no overlap", () {
        final list1 = [1, 2];
        final list2 = [3, 4];
        expect(list1.intersection(list2).toList(), isEmpty);
      });

      test("handles empty lists", () {
        final list1 = <int>[];
        final list2 = [1, 2, 3];
        expect(list1.intersection(list2).toList(), isEmpty);
        expect(list2.intersection(list1).toList(), isEmpty);
      });
    });
  });

  group("IterableX", () {
    group("minByOrNull", () {
      test("returns element with minimum value", () {
        final list = [3, 1, 4, 1, 5];
        expect(list.minByOrNull((x) => x), 1);
      });

      test("returns null for empty iterable", () {
        final list = <int>[];
        expect(list.minByOrNull((x) => x), isNull);
      });

      test("uses custom selector", () {
        final list = ["aaa", "b", "cc"];
        expect(list.minByOrNull((s) => s.length), "b");
      });
    });

    group("maxByOrNull", () {
      test("returns element with maximum value", () {
        final list = [3, 1, 4, 1, 5];
        expect(list.maxByOrNull((x) => x), 5);
      });

      test("returns null for empty iterable", () {
        final list = <int>[];
        expect(list.maxByOrNull((x) => x), isNull);
      });

      test("uses custom selector", () {
        final list = ["aaa", "b", "cc"];
        expect(list.maxByOrNull((s) => s.length), "aaa");
      });
    });

    group("excluding", () {
      test("filters out specified types", () {
        final list = <Object>[1, "a", 2, "b", 3.0];
        final result = list.excluding([String]).toList();
        expect(result, [1, 2, 3.0]);
      });

      test("returns all when no matching types", () {
        final list = [1, 2, 3];
        final result = list.excluding([String]).toList();
        expect(result, [1, 2, 3]);
      });

      test("returns empty when all excluded", () {
        final list = [1, 2, 3];
        final result = list.excluding([int]).toList();
        expect(result, isEmpty);
      });
    });
  });

  group("EntryMapIterable", () {
    test("toMap converts MapEntry iterable to map", () {
      final entries = [const MapEntry("a", 1), const MapEntry("b", 2)];
      expect(entries.toMap(), {"a": 1, "b": 2});
    });

    test("toMap handles empty iterable", () {
      final entries = <MapEntry<String, int>>[];
      expect(entries.toMap(), isEmpty);
    });
  });
}
