import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("page command accepts the complete captured origin", () {
    final conflict = pageEditOriginConflict(_document(), {
      DataPath.root.field("name"): (
        expected: const StringValue("Initial"),
        value: const StringValue("Renamed"),
      ),
      DataPath.root.field("chapter"): (
        expected: const StringValue("chapter"),
        value: const StringValue("next"),
      ),
    });

    expect(conflict, isNull);
  });

  test("page command rejects a concurrent value not shown at origin", () {
    final conflict = pageEditOriginConflict(_document(name: "Remote"), {
      DataPath.root.field("name"): (
        expected: const StringValue("Initial"),
        value: const StringValue("Local"),
      ),
    });

    expect(conflict, isNotNull);
    expect(conflict!.actualValue, _document(name: "Remote").confirmedValue);
  });

  test("page command rejects a field without a captured origin", () {
    final conflict = pageEditOriginConflict(_document(), {
      DataPath.root.field("priority"): (
        expected: null,
        value: IntegerValue(BigInt.from(5)),
      ),
    });

    expect(conflict, isNotNull);
  });
}

EditorDocument _document({String name = "Initial"}) => EditorDocument(
  rootType: RecordType(
    fields: const {
      "name": TypeField(name: "name", type: StringType()),
      "chapter": TypeField(name: "chapter", type: StringType()),
      "priority": TypeField(
        name: "priority",
        type: IntegerType(width: IntegerWidth.signed32),
      ),
    },
  ),
  typeCatalog: const TypeCatalog([]),
  confirmedValue: RecordValue({
    "name": StringValue(name),
    "chapter": const StringValue("chapter"),
    "priority": IntegerValue(BigInt.from(2)),
  }),
  revision: 4,
);
