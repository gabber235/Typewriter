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
      expectFormatException(converter, {
        "kind": "record",
        "fields": {"value": null},
      }, r"Expected an object at $.fields.value, got null");
    });

    test("reports the exact path for a non-string record key", () {
      expectFormatException(converter, {
        "kind": "record",
        "fields": <Object?, Object?>{
          1: {"kind": "unit"},
        },
      }, r"Expected a string object key at $.fields.keys[0], got an integer");
    });

    test("reports malformed nested list and map paths", () {
      final cases = <(Map<String, Object?>, String)>[
        (
          {
            "kind": "list",
            "values": [
              {
                "kind": "list",
                "values": [null],
              },
            ],
          },
          r"Expected an object at $.values[0].values[0], got null",
        ),
        (
          {
            "kind": "map",
            "entries": [
              {
                "key": {"kind": "string", "value": "key"},
                "value": null,
              },
            ],
          },
          r"Expected an object at $.entries[0].value, got null",
        ),
        (
          {"kind": "map", "entries": <String, Object?>{}},
          r"Expected a list at $.entries, got an object",
        ),
      ];

      for (final (json, message) in cases) {
        expectFormatException(converter, json, message);
      }
    });

    test("reports invalid timestamps and byte values at their exact path", () {
      final cases = <(Map<String, Object?>, String)>[
        (
          {"kind": "timestamp", "value": "invalid date"},
          r"Expected an ISO 8601 timestamp string at $.value, got a string",
        ),
        (
          {
            "kind": "bytes",
            "value": [0, "invalid"],
          },
          r"Expected an integer at $.value[1], got a string",
        ),
        (
          {
            "kind": "bytes",
            "value": [256],
          },
          r"Expected an integer from 0 through 255 at $.value[0], got an integer",
        ),
      ];

      for (final (json, message) in cases) {
        expectFormatException(converter, json, message);
      }
    });

    test("reports malformed polymorphic references at their exact path", () {
      final cases = <(Map<String, Object?>, String)>[
        (
          polymorphicJson(
            type: {
              "id": {"kind": "qualified", "namespace": null, "name": "Named"},
              "revision": 2,
              "arguments": <Object?>[],
            },
          ),
          r"Expected a string at $.type.id.namespace, got null",
        ),
        (
          polymorphicJson(
            type: {
              "id": {
                "kind": "qualified",
                "namespace": "example",
                "name": "Named",
              },
              "revision": "two",
              "arguments": <Object?>[],
            },
          ),
          r"Expected an integer at $.type.revision, got a string",
        ),
        (
          polymorphicJson(
            type: {
              "id": {
                "kind": "qualified",
                "namespace": "example",
                "name": "Named",
              },
              "revision": 2,
              "arguments": [null],
            },
          ),
          r"Expected an object at $.type.arguments[0], got null",
        ),
      ];

      for (final (json, message) in cases) {
        expectFormatException(converter, json, message);
      }
    });
  });
}

void expectFormatException(
  DataValueJsonConverter converter,
  Map<String, Object?> json,
  String message,
) {
  expect(
    () => converter.fromJson(json),
    throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        "message",
        message,
      ),
    ),
  );
}

Map<String, Object?> polymorphicJson({required Object? type}) => {
  "kind": "polymorphic",
  "type": type,
  "value": {"kind": "unit"},
};
