import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("DataValue readers", () {
    test("read only their exact variant", () {
      final values = <DataValue>[
        const UnitValue(),
        const BooleanValue(true),
        IntegerValue(BigInt.from(42)),
        const FloatValue(1.5),
        DecimalValue("1.50"),
        const StringValue("text"),
        BytesValue(Uint8List.fromList([1, 2])),
        TimestampValue(DateTime.utc(2026, 9, 10)),
        const DurationValue(Duration(seconds: 2)),
        const ListValue([StringValue("item")]),
        const MapValue([
          DataMapEntry(key: StringValue("key"), value: StringValue("value")),
        ]),
        RecordValue({"name": const StringValue("record")}),
        PolymorphicValue(
          concreteType: ResolvedTypeRef(
            id: const TypeId.qualified(namespace: "example", name: "Type"),
            revision: 1,
          ),
          value: const StringValue("wrapped"),
        ),
      ];

      expect(values[0].asUnitOrNull, isA<UnitValue>());
      expect(values[1].asBooleanOrNull, true);
      expect(values[2].asBigIntOrNull, BigInt.from(42));
      expect(values[3].asDoubleOrNull, 1.5);
      expect(values[4].asDecimalOrNull, "1.50");
      expect(values[5].asStringOrNull, "text");
      expect(values[6].asBytesOrNull, orderedEquals([1, 2]));
      expect(values[7].asDateTimeOrNull, DateTime.utc(2026, 9, 10));
      expect(values[8].asDurationOrNull, const Duration(seconds: 2));
      expect(values[9].asListOrNull, isA<List<DataValue>>());
      expect(values[10].asMapEntriesOrNull, isA<List<DataMapEntry>>());
      expect(values[11].asRecordOrNull, isA<Map<String, DataValue>>());
      expect(values[12].asPolymorphicOrNull, isA<PolymorphicValue>());

      expect(values[1].asStringOrNull, isNull);
      expect(values[2].asDoubleOrNull, isNull);
      expect(values[5].asDecimalOrNull, isNull);
    });
  });

  test("native values write their natural DataValue variant", () {
    expect("text".asValue, const StringValue("text"));
    expect(true.asValue, const BooleanValue(true));
    expect(42.asValue, IntegerValue(BigInt.from(42)));
    expect(BigInt.from(42).asValue, IntegerValue(BigInt.from(42)));
    expect(1.5.asValue, const FloatValue(1.5));
    expect(
      Uint8List.fromList([1, 2]).asValue,
      BytesValue(Uint8List.fromList([1, 2])),
    );
    expect(
      DateTime.utc(2026, 9, 10).asValue,
      TimestampValue(DateTime.utc(2026, 9, 10)),
    );
    expect(
      const Duration(seconds: 2).asValue,
      const DurationValue(Duration(seconds: 2)),
    );
    expect(
      <DataValue>[const StringValue("item")].asValue,
      const ListValue([StringValue("item")]),
    );
    expect(
      <String, DataValue>{"name": const StringValue("record")}.asValue,
      RecordValue({"name": const StringValue("record")}),
    );
    expect(
      const <DataMapEntry>[
        DataMapEntry(key: StringValue("key"), value: StringValue("value")),
      ].asValue,
      const MapValue([
        DataMapEntry(key: StringValue("key"), value: StringValue("value")),
      ]),
    );
    expect(
      <DataValue, DataValue>{
        const StringValue("key"): const StringValue("value"),
      }.asValue,
      const MapValue([
        DataMapEntry(key: StringValue("key"), value: StringValue("value")),
      ]),
    );
  });
}
