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
}
