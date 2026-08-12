import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire_diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/path.dart"
    as wire_path;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final reference = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "record"),
    revision: 2,
  );
  final codec = SkirEditorCodec(TypeRegistry(TypeCatalog(const [])));

  test("round trips every type expression variant", () {
    final expressions = <TypeExpression>[
      const UnitType(),
      const BooleanType(),
      const StringType(
        minimumLength: 1,
        maximumLength: 12,
        patterns: [r"^[a-z]+$"],
      ),
      const BytesType(minimumLength: 1, maximumLength: 8),
      IntegerType(
        width: IntegerWidth.signed16,
        minimum: BigInt.from(-20),
        maximum: BigInt.from(20),
      ),
      const IntegerType(width: IntegerWidth.unsigned64),
      const FloatType(width: FloatWidth.float32, minimum: 0.5, maximum: 8.5),
      const DecimalType(minimum: "0.01", maximum: "99.99"),
      const TimestampType(),
      const DurationType(),
      EnumType(
        valueType: const StringType(),
        values: const [StringValue("draft"), StringValue("published")],
      ),
      const ListType(
        element: StringType(),
        minimumLength: 1,
        maximumLength: 4,
        unique: true,
      ),
      const MapType(
        key: StringType(),
        value: BooleanType(),
        minimumLength: 1,
        maximumLength: 3,
      ),
      RecordType(
        fields: const {
          "name": TypeField(
            name: "name",
            type: StringType(),
            initialValue: StringValue("new"),
          ),
        },
        closed: false,
      ),
      NamedType(reference),
      const ParameterType("item"),
    ];

    for (final expression in expressions) {
      final result = codec.typeCodec.encodeExpression(expression);
      expect(
        result.valueOrNull,
        isNotNull,
        reason: "${expression.runtimeType}: ${result.diagnostics}",
      );
      final encoded = result.valueOrNull!;
      final bytes = wire_type.TypeExpression.serializer.toBytes(encoded);
      final wire = wire_type.TypeExpression.serializer.fromBytes(bytes);
      final decoded = codec.typeCodec.decodeExpression(wire).valueOrNull!;
      expect(typeExpressionsEqual(decoded, expression), isTrue);
    }
  });

  test("rejects enum values that do not match the declared value type", () {
    final stringType = codec.typeCodec
        .encodeExpression(const StringType())
        .valueOrNull!;
    final result = codec.typeCodec.decodeExpression(
      wire_type.TypeExpression.createEnumType(
        valueType: stringType,
        canonicalValues: [
          wire_type.TypedValue.wrapString("draft"),
          wire_type.TypedValue.wrapBoolean(true),
        ],
      ),
    );

    expect(result.valueOrNull, isNull);
    expect(result.diagnostics, isNotEmpty);
  });

  test("round trips every typed value variant", () {
    final values = <DataValue>[
      const UnitValue(),
      const BooleanValue(true),
      IntegerValue(BigInt.from(-42)),
      IntegerValue((BigInt.one << 64) - BigInt.one),
      const FloatValue(4.25),
      DecimalValue("123.450"),
      const StringValue("value"),
      BytesValue(Uint8List.fromList([0, 127, 255])),
      TimestampValue(DateTime.utc(2026, 8, 10, 12, 30)),
      const DurationValue(Duration(milliseconds: 1234)),
      ListValue(const [StringValue("a"), BooleanValue(false)]),
      MapValue([DataMapEntry(key: _one, value: const StringValue("one"))]),
      RecordValue(const {"field": StringValue("record")}),
      PolymorphicValue(
        concreteType: reference,
        value: RecordValue(const {"field": StringValue("named")}),
      ),
    ];

    for (final value in values) {
      final encoded = codec.encodeValue(value).valueOrNull!;
      final bytes = wire_type.TypedValue.serializer.toBytes(encoded);
      final wire = wire_type.TypedValue.serializer.fromBytes(bytes);
      expect(codec.decodeValue(wire).valueOrNull, value);
    }
  });

  test("round trips every structured path segment", () {
    final path = DataPath.root
        .field("items")
        .index(2)
        .mapKey(const StringValue("key"));
    final encoded = codec.encodePath(path).valueOrNull!;
    final bytes = wire_path.DataPath.serializer.toBytes(encoded);
    final wire = wire_path.DataPath.serializer.fromBytes(bytes);

    expect(codec.decodePath(wire).valueOrNull, path);
  });

  test("round trips exact nominal references", () {
    final generic = ResolvedTypeRef(
      id: const TypeId.option(),
      revision: 1,
      arguments: [NamedType(reference)],
    );
    final encoded = codec.encodeType(generic).valueOrNull!;
    final bytes = wire_type.ResolvedTypeRef.serializer.toBytes(encoded);
    final wire = wire_type.ResolvedTypeRef.serializer.fromBytes(bytes);

    expect(codec.decodeType(wire).valueOrNull, generic);
  });

  test("round trips resolved and diagnostic binding outcomes", () {
    final path = codec.encodePath(DataPath.root).valueOrNull!;
    final binding = wire_binding.BindingRef(
      bindingId: wire_binding.BindingId(value: 1),
      path: path,
    );
    final outcomes = <wire_binding.BindingResolution>[
      wire_binding.BindingResolution.createResolved(
        reference: binding,
        valueType: codec.typeCodec
            .encodeExpression(const StringType())
            .valueOrNull!,
        value: wire_type.TypedValue.wrapString("value"),
        writable: true,
        revision: 2,
      ),
      wire_binding.BindingResolution.wrapDiagnostics([
        wire_diagnostic.TypeDiagnostic(
          code: wire_diagnostic.DiagnosticCode.invalidPath,
          severity: wire_diagnostic.DiagnosticSeverity.error,
          message: "Invalid binding",
          path: path,
          relatedType: null,
          details: const [],
        ),
      ]),
    ];
    for (final outcome in outcomes) {
      final bytes = wire_binding.BindingResolution.serializer.toBytes(outcome);
      expect(
        wire_binding.BindingResolution.serializer.toBytes(
          wire_binding.BindingResolution.serializer.fromBytes(bytes),
        ),
        bytes,
      );
    }
  });
}

final _one = IntegerValue(BigInt.one);
