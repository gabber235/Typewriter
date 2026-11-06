import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("two different enum cases never share a canonical key", () {
    final keys = {
      for (final value in [
        enumValue("Door", "Open"),
        enumValue("Door", "Shut"),
        enumValue("Window", "Open"),
      ])
        canonicalAuthoredValue(value),
    };

    expect(keys, hasLength(3));
  });
}
