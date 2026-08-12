import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("strict typed value JSON", () {
    final converter = const DataValueJsonConverter();
    final concreteType = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "example", name: "Named"),
      revision: 2,
    );

    final cases = <DataValue>[
      const UnitValue(),
      const BooleanValue(true),
      IntegerValue(BigInt.parse("18446744073709551615")),
      const FloatValue(1.25),
      DecimalValue("1234567890.001"),
      const StringValue("text"),
      BytesValue(Uint8List.fromList([0, 127, 255])),
      TimestampValue(DateTime.utc(2026, 8, 9, 12, 30)),
      const DurationValue(Duration(microseconds: 4512)),
      ListValue([const StringValue("first"), const StringValue("second")]),
      MapValue([
        DataMapEntry(
          key: IntegerValue(BigInt.zero),
          value: const StringValue("zero"),
        ),
      ]),
      RecordValue({
        "required": const BooleanValue(true),
        "nested": ListValue([IntegerValue(BigInt.one)]),
      }),
      PolymorphicValue(
        concreteType: concreteType,
        value: const StringValue("payload"),
      ),
    ];

    for (final value in cases) {
      test("round trips ${value.runtimeType}", () {
        expect(converter.fromJson(converter.toJson(value)), value);
      });
    }

    test("rejects an untagged scalar", () {
      expect(() => converter.fromJson({"value": "raw"}), throwsFormatException);
    });

    test("represents unit with an explicit envelope", () {
      expect(converter.toJson(const UnitValue()), {"kind": "unit"});
    });

    test("rejects null inside a record envelope", () {
      expect(
        () => converter.fromJson({
          "kind": "record",
          "fields": {"value": null},
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group("structured typed mutation", () {
    final root = RecordValue({
      "profile": RecordValue({"name": const StringValue("Before")}),
      "items": ListValue([
        RecordValue({"enabled": const BooleanValue(false)}),
      ]),
      "scores": MapValue([
        DataMapEntry(
          key: IntegerValue(BigInt.one),
          value: IntegerValue(BigInt.from(10)),
        ),
      ]),
      "choice": PolymorphicValue(
        concreteType: ResolvedTypeRef(
          id: const QualifiedTypeId(namespace: "example", name: "Choice"),
          revision: 1,
        ),
        value: RecordValue({"value": const StringValue("old")}),
      ),
    });

    test("reads nested record fields", () {
      final path = DataPath.root.field("profile").field("name");

      expect(path.read(root).valueOrNull, const StringValue("Before"));
    });

    test("replaces a list member immutably", () {
      final path = DataPath.root.field("items").index(0).field("enabled");
      final updated = path.replace(root, const BooleanValue(true)).valueOrNull;

      expect(path.read(updated!).valueOrNull, const BooleanValue(true));
      expect(path.read(root).valueOrNull, const BooleanValue(false));
    });

    test("uses typed nonstring map keys", () {
      final path = DataPath.root
          .field("scores")
          .mapKey(IntegerValue(BigInt.one));
      final updated = path.replace(root, IntegerValue(BigInt.from(20)));

      expect(updated.valueOrNull, isA<RecordValue>());
      expect(
        path.read(updated.valueOrNull!).valueOrNull,
        IntegerValue(BigInt.from(20)),
      );
    });

    test("traverses a polymorphic value transparently", () {
      final path = DataPath.root.field("choice").field("value");

      expect(path.read(root).valueOrNull, const StringValue("old"));
    });

    test("reports absent fields without manufacturing null", () {
      final result = DataPath.root.field("missing").read(root);

      expect(result.valueOrNull, isNull);
      expect(result.diagnostics.single.code, TypeDiagnosticCode.invalidPath);
    });
  });
}
