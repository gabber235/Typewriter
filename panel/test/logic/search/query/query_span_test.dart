import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/search/query/query.dart";

void main() {
  test("containsOffset true for offset in range", () {
    final range = QueryRange(5, 10);
    expect(range.containsOffset(7), isTrue);
  });

  test("containsOffset false for offset before", () {
    final range = QueryRange(5, 10);
    expect(range.containsOffset(3), isFalse);
  });

  test("containsOffset false for offset after", () {
    final range = QueryRange(5, 10);
    expect(range.containsOffset(12), isFalse);
  });

  test("containsOffset true for offset at start", () {
    final range = QueryRange(5, 10);
    expect(range.containsOffset(5), isTrue);
  });

  test("containsOffset false for offset at end", () {
    final range = QueryRange(5, 10);
    expect(range.containsOffset(10), isTrue);
  });
}
