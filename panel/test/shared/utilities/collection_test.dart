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

    group("randomSubset", () {
      test("returns empty list when count is 0", () {
        final list = [1, 2, 3];
        expect(list.randomSubset(0), isEmpty);
      });

      test("returns empty list when count exceeds length", () {
        final list = [1, 2, 3];
        expect(list.randomSubset(5), isEmpty);
      });

      test("returns empty list when count is negative", () {
        final list = [1, 2, 3];
        expect(list.randomSubset(-1), isEmpty);
      });

      test("returns correct number of unique elements", () {
        final list = [1, 2, 3, 4, 5];
        final subset = list.randomSubset(3);
        expect(subset.length, 3);
        expect(subset.toSet().length, 3);
        for (final item in subset) {
          expect(list, contains(item));
        }
      });

      test("returns all elements when count equals length", () {
        final list = [1, 2, 3];
        final subset = list.randomSubset(3);
        expect(subset.length, 3);
        expect(subset.toSet(), list.toSet());
      });
    });

    group("indices", () {
      test("returns empty list for empty list", () {
        final list = <int>[];
        expect(list.indices, isEmpty);
      });

      test("returns indices for non-empty list", () {
        final list = ["a", "b", "c"];
        expect(list.indices, [0, 1, 2]);
      });
    });

    group("joinWith", () {
      test("inserts separator between elements", () {
        final list = [1, 2, 3];
        final result = list.joinWith(() => 0);
        expect(result, [1, 0, 2, 0, 3]);
      });

      test("returns single element list unchanged", () {
        final list = [1];
        final result = list.joinWith(() => 0);
        expect(result, [1]);
      });

      test("returns empty list unchanged", () {
        final list = <int>[];
        final result = list.joinWith(() => 0);
        expect(result, isEmpty);
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

    group("allAre", () {
      test("returns true when all elements match type", () {
        final list = <num>[1, 2, 3];
        expect(list.allAre<int>(), isTrue);
      });

      test("returns false when elements have mixed types", () {
        final list = <num>[1, 2.0, 3];
        expect(list.allAre<int>(), isFalse);
      });

      test("returns false for empty iterable", () {
        final list = <num>[];
        expect(list.allAre<int>(), isFalse);
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
