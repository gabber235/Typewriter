import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const range = QueryRange(5, 10);
  final offsets = {
    "before the start": (offset: 3, contains: false),
    "at the start": (offset: 5, contains: true),
    "inside": (offset: 7, contains: true),
    "at the end, where a cursor ends the token": (offset: 10, contains: true),
    "after the end": (offset: 12, contains: false),
  };
  for (final MapEntry(key: name, value: (:offset, :contains))
      in offsets.entries) {
    test("containsOffset is $contains for an offset $name", () {
      expect(range.containsOffset(offset), contains);
    });
  }
}
