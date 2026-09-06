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

  test("maps every type expression variant and its fields", () {
    final expressions = <(TypeExpression, wire_type.TypeExpression_kind)>[
      (const AnyType(), wire_type.TypeExpression_kind.anyConst),
      (const UnitType(), wire_type.TypeExpression_kind.unitConst),
      (const BooleanType(), wire_type.TypeExpression_kind.booleanConst),
      (
        const StringType(
          minimumLength: 1,
          maximumLength: 12,
          patterns: [r"^[a-z]+$"],
        ),
        wire_type.TypeExpression_kind.stringWrapper,
      ),
      (
        const BytesType(minimumLength: 1, maximumLength: 8),
        wire_type.TypeExpression_kind.bytesWrapper,
      ),
      (
        IntegerType(
          width: IntegerWidth.signed16,
          minimum: BigInt.from(-20),
          maximum: BigInt.from(20),
        ),
        wire_type.TypeExpression_kind.signedIntegerWrapper,
      ),
      (
        const IntegerType(width: IntegerWidth.unsigned64),
        wire_type.TypeExpression_kind.unsignedIntegerWrapper,
      ),
      (
        const FloatType(width: FloatWidth.float32, minimum: 0.5, maximum: 8.5),
        wire_type.TypeExpression_kind.floatWrapper,
      ),
      (
        const DecimalType(minimum: "0.01", maximum: "99.99"),
        wire_type.TypeExpression_kind.decimalWrapper,
      ),
      (const TimestampType(), wire_type.TypeExpression_kind.timestampConst),
      (const DurationType(), wire_type.TypeExpression_kind.durationConst),
      (
        EnumType(
          valueType: const StringType(),
          values: const [StringValue("draft"), StringValue("published")],
        ),
        wire_type.TypeExpression_kind.enumTypeWrapper,
      ),
      (
        const ListType(
          element: StringType(),
          minimumLength: 1,
          maximumLength: 4,
          unique: true,
        ),
        wire_type.TypeExpression_kind.listWrapper,
      ),
      (
        const MapType(
          key: StringType(),
          value: BooleanType(),
          minimumLength: 1,
          maximumLength: 3,
        ),
        wire_type.TypeExpression_kind.mapWrapper,
      ),
      (
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
        wire_type.TypeExpression_kind.recordWrapper,
      ),
      (NamedType(reference), wire_type.TypeExpression_kind.namedWrapper),
      (
        const ParameterType("item"),
        wire_type.TypeExpression_kind.parameterWrapper,
      ),
    ];

    for (final (expression, expectedKind) in expressions) {
      final result = codec.typeCodec.encodeExpression(expression);
      expect(
        result.valueOrNull,
        isNotNull,
        reason: "${expression.runtimeType}: ${result.diagnostics}",
      );
      final encoded = result.valueOrNull!;
      expect(
        encoded.kind,
        expectedKind,
        reason: expression.runtimeType.toString(),
      );
      final decoded = codec.typeCodec.decodeExpression(encoded).valueOrNull!;
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

  test("maps every typed value variant and its payload", () {
    final values = <(DataValue, wire_type.TypedValue_kind)>[
      (const UnitValue(), wire_type.TypedValue_kind.unitConst),
      (const BooleanValue(true), wire_type.TypedValue_kind.booleanWrapper),
      (
        IntegerValue(BigInt.from(-42)),
        wire_type.TypedValue_kind.signedSixtyFourWrapper,
      ),
      (
        IntegerValue((BigInt.one << 64) - BigInt.one),
        wire_type.TypedValue_kind.unsignedSixtyFourWrapper,
      ),
      (const FloatValue(4.25), wire_type.TypedValue_kind.floatSixtyFourWrapper),
      (DecimalValue("123.450"), wire_type.TypedValue_kind.decimalWrapper),
      (const StringValue("value"), wire_type.TypedValue_kind.stringWrapper),
      (
        BytesValue(Uint8List.fromList([0, 127, 255])),
        wire_type.TypedValue_kind.bytesWrapper,
      ),
      (
        TimestampValue(DateTime.utc(2026, 8, 10, 12, 30)),
        wire_type.TypedValue_kind.timestampWrapper,
      ),
      (
        const DurationValue(Duration(milliseconds: 1234)),
        wire_type.TypedValue_kind.durationWrapper,
      ),
      (
        ListValue(const [StringValue("a"), BooleanValue(false)]),
        wire_type.TypedValue_kind.listWrapper,
      ),
      (
        MapValue([DataMapEntry(key: _one, value: const StringValue("one"))]),
        wire_type.TypedValue_kind.mapWrapper,
      ),
      (
        RecordValue(const {"field": StringValue("record")}),
        wire_type.TypedValue_kind.recordWrapper,
      ),
      (
        PolymorphicValue(
          concreteType: reference,
          value: RecordValue(const {"field": StringValue("named")}),
        ),
        wire_type.TypedValue_kind.namedWrapper,
      ),
    ];

    for (final (value, expectedKind) in values) {
      final encoded = codec.encodeValue(value).valueOrNull!;
      expect(encoded.kind, expectedKind, reason: value.runtimeType.toString());
      expect(codec.decodeValue(encoded).valueOrNull, value);
    }
  });

  test("maps every structured path segment and payload", () {
    final path = DataPath.root
        .field("items")
        .index(2)
        .mapKey(const StringValue("key"));
    final encoded = codec.encodePath(path).valueOrNull!;
    expect(encoded.segments.map((segment) => segment.kind), [
      wire_path.DataPathSegment_kind.fieldWrapper,
      wire_path.DataPathSegment_kind.indexWrapper,
      wire_path.DataPathSegment_kind.mapKeyWrapper,
    ]);

    expect(codec.decodePath(encoded).valueOrNull, path);
  });

  test("maps exact nominal reference identity and arguments", () {
    final generic = ResolvedTypeRef(
      id: const TypeId.option(),
      revision: 1,
      arguments: [NamedType(reference)],
    );
    final encoded = codec.encodeType(generic).valueOrNull!;
    expect(encoded.typeId.kind, wire_type.TypeId_kind.builtinWrapper);
    expect(
      (encoded.typeId as wire_type.TypeId_builtinWrapper).value.kind,
      wire_type.BuiltinTypeId_kind.optionConst,
    );
    expect(encoded.revision, 1);
    expect(encoded.arguments, hasLength(1));
    expect(
      encoded.arguments.single.kind,
      wire_type.TypeExpression_kind.namedWrapper,
    );

    expect(codec.decodeType(encoded).valueOrNull, generic);
  });

  test("preserves every binding outcome field on the wire", () {
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
    expect(
      outcomes[0].kind,
      wire_binding.BindingResolution_kind.resolvedWrapper,
    );
    final resolved =
        (outcomes[0] as wire_binding.BindingResolution_resolvedWrapper).value;
    expect(resolved.reference, binding);
    expect(
      resolved.valueType.kind,
      wire_type.TypeExpression_kind.stringWrapper,
    );
    expect(resolved.value, wire_type.TypedValue.wrapString("value"));
    expect(resolved.writable, isTrue);
    expect(resolved.revision, 2);

    expect(
      outcomes[1].kind,
      wire_binding.BindingResolution_kind.diagnosticsWrapper,
    );
    final diagnostics =
        (outcomes[1] as wire_binding.BindingResolution_diagnosticsWrapper)
            .value;
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.code, wire_diagnostic.DiagnosticCode.invalidPath);
    expect(diagnostics.single.message, "Invalid binding");
  });
}

final _one = IntegerValue(BigInt.one);
