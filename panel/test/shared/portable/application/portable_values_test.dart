import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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

  test(
    "two content types with one key on two resources never compare equal",
    () {
      final keys = {
        for (final resource in ["reward", "door"])
          canonicalAuthoredValue(
            skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: contentTypeDefinition(resource, "k1"),
                arguments: const [],
              ),
              payload: skir.DataValue.unit,
            ),
          ),
      };

      expect(keys, hasLength(2));
    },
  );
}
