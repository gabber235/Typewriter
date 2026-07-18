import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/utils/collection.dart";

void main() {
  group("updateByKey", () {
    test("replaces matching value without duplication", () {
      final previous = [(id: 1, name: "Before")];
      final updated = (id: 1, name: "After");

      final result = previous.upsertByKey((value) => value.id, updated);

      expect(result, [updated]);
    });

    test("appends value when key is absent", () {
      final previous = [(id: 1, name: "Existing")];
      final updated = (id: 2, name: "Added");

      final result = previous.upsertByKey((value) => value.id, updated);

      expect(result, [previous.single, updated]);
    });

    test("creates list when source is null", () {
      final List<({int id, String name})>? previous = null;
      final updated = (id: 1, name: "Added");

      final result = previous.upsertByKey((value) => value.id, updated);

      expect(result, [updated]);
    });
  });
}
