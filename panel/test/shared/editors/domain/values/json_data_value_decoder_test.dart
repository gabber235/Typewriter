import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));

  group("decodeJsonDataValue", () {
    test("decodes every supported scalar representation", () {
      final cases = <(Object?, TypeExpression, DataValue)>[
        (null, const UnitType(), const UnitValue()),
        (true, const BooleanType(), const BooleanValue(true)),
        ("value", const StringType(), const StringValue("value")),
        ("AQID", const BytesType(), BytesValue(Uint8List.fromList([1, 2, 3]))),
        (
          12,
          const IntegerType(width: IntegerWidth.signed64),
          IntegerValue(BigInt.from(12)),
        ),
        (
          1.5,
          const FloatType(width: FloatWidth.float64),
          const FloatValue(1.5),
        ),
        ("12.50", const DecimalType(), DecimalValue("12.50")),
        (
          "2026-08-14T10:00:00Z",
          const TimestampType(),
          TimestampValue(DateTime.utc(2026, 8, 14, 10)),
        ),
        (
          2000,
          const DurationType(),
          const DurationValue(Duration(microseconds: 2000)),
        ),
      ];

      for (final (source, type, expected) in cases) {
        expect(
          decodeJsonDataValue(source, type, registry: registry).valueOrNull,
          expected,
        );
      }
    });

    test("strictly rejects values that do not match the requested type", () {
      final cases = <(Object?, TypeExpression)>[
        (1, const BooleanType()),
        (true, const StringType()),
        (1.5, const IntegerType(width: IntegerWidth.signed64)),
        ("1.5", const FloatType(width: FloatWidth.float64)),
        (const [1], const MapType(key: StringType(), value: StringType())),
      ];

      for (final (source, type) in cases) {
        expect(
          decodeJsonDataValue(source, type, registry: registry),
          isA<TypeFailure<DataValue>>(),
        );
      }
    });

    test("decodes nested lists, maps, and closed records", () {
      final type = RecordType(
        closed: true,
        fields: const {
          "name": TypeField(name: "name", type: StringType()),
          "tags": TypeField(
            name: "tags",
            type: ListType(element: StringType()),
          ),
          "labels": TypeField(
            name: "labels",
            type: MapType(key: StringType(), value: StringType()),
          ),
        },
      );

      final result = decodeJsonDataValue(
        {
          "name": "Quest",
          "tags": ["story", "daily"],
          "labels": {"en": "Quest"},
        },
        type,
        registry: registry,
      );

      expect(
        result.valueOrNull,
        RecordValue({
          "name": const StringValue("Quest"),
          "tags": const ListValue([StringValue("story"), StringValue("daily")]),
          "labels": const MapValue([
            DataMapEntry(key: StringValue("en"), value: StringValue("Quest")),
          ]),
        }),
      );
    });

    test("applies field defaults and rejects record shape drift", () {
      final type = RecordType(
        closed: true,
        fields: const {
          "name": TypeField(name: "name", type: StringType()),
          "enabled": TypeField(
            name: "enabled",
            type: BooleanType(),
            initialValue: BooleanValue(true),
          ),
        },
      );

      final withDefault = decodeJsonDataValue(
        {"name": "Quest"},
        type,
        registry: registry,
      );
      final missing = decodeJsonDataValue(
        <String, Object?>{},
        type,
        registry: registry,
      );
      final unknown = decodeJsonDataValue(
        {"name": "Quest", "extra": true},
        type,
        registry: registry,
      );

      expect(
        (withDefault.valueOrNull! as RecordValue).fields["enabled"],
        const BooleanValue(true),
      );
      expect(missing.diagnostics.single.message, "Missing field name");
      expect(unknown.diagnostics.single.message, "Unknown field extra");
    });

    test("resolves nominal and enum types before decoding", () {
      final reference = ResolvedTypeRef(
        id: const QualifiedTypeId(namespace: "test", name: "identifier"),
        revision: 1,
      );
      final nominalRegistry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: reference,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
          ),
        ]),
      );
      final enumeration = EnumType(
        valueType: const StringType(),
        values: const [StringValue("allowed")],
      );

      expect(
        decodeJsonDataValue(
          "value",
          NamedType(reference),
          registry: nominalRegistry,
        ).valueOrNull,
        const StringValue("value"),
      );
      expect(
        decodeJsonDataValue("denied", enumeration, registry: registry),
        isA<TypeFailure<DataValue>>(),
      );
    });

    test("infers recursive JSON values for any", () {
      final result = decodeJsonDataValue(
        {
          "enabled": true,
          "values": [1, "two"],
        },
        const AnyType(),
        registry: registry,
      );

      expect(result.valueOrNull, isA<RecordValue>());
      final record = result.valueOrNull! as RecordValue;
      expect(record.fields["enabled"], const BooleanValue(true));
      expect(
        record.fields["values"],
        ListValue([IntegerValue(BigInt.one), const StringValue("two")]),
      );
    });
  });
}
