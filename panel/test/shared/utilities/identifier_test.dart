import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const validValues = ["abc", "a_b", "main_story", "book2"];
  const invalidValues = [
    "",
    "ab",
    "_main",
    "main_",
    "main__story",
    "MainStory",
    "main story",
  ];

  test("accepts valid identifiers", () {
    for (final value in validValues) {
      expect(value.isValidIdentifier, isTrue, reason: value);
      expect(
        StringValue(value).validateAgainst(identifierStringType),
        isEmpty,
        reason: value,
      );
    }
  });

  test("rejects invalid identifiers", () {
    for (final value in invalidValues) {
      expect(value.isValidIdentifier, isFalse, reason: value);
      expect(
        StringValue(value).validateAgainst(identifierStringType),
        isNotEmpty,
        reason: value,
      );
    }
  });
}
