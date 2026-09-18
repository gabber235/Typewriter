import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final reference = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "record"),
    revision: 2,
  );
  final codec = SkirEditorCodec(TypeRegistry(TypeCatalog(const [])));

  test("maps every type expression variant and its fields", () {
    final expressions = <(TypeExpression, skir.TypeExpression_kind)>[
      (const AnyType(), skir.TypeExpression_kind.anyConst),
      (const UnitType(), skir.TypeExpression_kind.unitConst),
      (const BooleanType(), skir.TypeExpression_kind.booleanConst),
      (
        const StringType(
          minimumLength: 1,
          maximumLength: 12,
          patterns: [r"^[a-z]+$"],
        ),
        skir.TypeExpression_kind.stringWrapper,
      ),
      (
        const BytesType(minimumLength: 1, maximumLength: 8),
        skir.TypeExpression_kind.bytesWrapper,
      ),
      (
        IntegerType(
          width: IntegerWidth.signed16,
          minimum: BigInt.from(-20),
          maximum: BigInt.from(20),
        ),
        skir.TypeExpression_kind.signedIntegerWrapper,
      ),
      (
        const IntegerType(width: IntegerWidth.unsigned64),
        skir.TypeExpression_kind.unsignedIntegerWrapper,
      ),
      (
        const FloatType(width: FloatWidth.float32, minimum: 0.5, maximum: 8.5),
        skir.TypeExpression_kind.floatWrapper,
      ),
      (
        const DecimalType(minimum: "0.01", maximum: "99.99"),
        skir.TypeExpression_kind.decimalWrapper,
      ),
      (const TimestampType(), skir.TypeExpression_kind.timestampConst),
      (const DurationType(), skir.TypeExpression_kind.durationConst),
      (
        EnumType(
          valueType: const StringType(),
          values: const [StringValue("draft"), StringValue("published")],
        ),
        skir.TypeExpression_kind.enumTypeWrapper,
      ),
      (
        const ListType(
          element: StringType(),
          minimumLength: 1,
          maximumLength: 4,
          unique: true,
        ),
        skir.TypeExpression_kind.listWrapper,
      ),
      (
        const MapType(
          key: StringType(),
          value: BooleanType(),
          minimumLength: 1,
          maximumLength: 3,
        ),
        skir.TypeExpression_kind.mapWrapper,
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
        skir.TypeExpression_kind.recordWrapper,
      ),
      (NamedType(reference), skir.TypeExpression_kind.namedWrapper),
      (const ParameterType("item"), skir.TypeExpression_kind.parameterWrapper),
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
      skir.TypeExpression.createEnumType(
        valueType: stringType,
        canonicalValues: [
          skir.TypedValue.wrapString("draft"),
          skir.TypedValue.wrapBoolean(true),
        ],
      ),
    );

    expect(result.valueOrNull, isNull);
    expect(result.diagnostics, isNotEmpty);
  });

  test("maps every typed value variant and its payload", () {
    final values = <(DataValue, skir.TypedValue_kind)>[
      (const UnitValue(), skir.TypedValue_kind.unitConst),
      (const BooleanValue(true), skir.TypedValue_kind.booleanWrapper),
      (
        IntegerValue(BigInt.from(-42)),
        skir.TypedValue_kind.signedSixtyFourWrapper,
      ),
      (
        IntegerValue((BigInt.one << 64) - BigInt.one),
        skir.TypedValue_kind.unsignedSixtyFourWrapper,
      ),
      (const FloatValue(4.25), skir.TypedValue_kind.floatSixtyFourWrapper),
      (DecimalValue("123.450"), skir.TypedValue_kind.decimalWrapper),
      (const StringValue("value"), skir.TypedValue_kind.stringWrapper),
      (
        BytesValue(Uint8List.fromList([0, 127, 255])),
        skir.TypedValue_kind.bytesWrapper,
      ),
      (
        TimestampValue(DateTime.utc(2026, 8, 10, 12, 30)),
        skir.TypedValue_kind.timestampWrapper,
      ),
      (
        const DurationValue(Duration(milliseconds: 1234)),
        skir.TypedValue_kind.durationWrapper,
      ),
      (
        ListValue(const [StringValue("a"), BooleanValue(false)]),
        skir.TypedValue_kind.listWrapper,
      ),
      (
        MapValue([DataMapEntry(key: _one, value: const StringValue("one"))]),
        skir.TypedValue_kind.mapWrapper,
      ),
      (
        RecordValue(const {"field": StringValue("record")}),
        skir.TypedValue_kind.recordWrapper,
      ),
      (
        PolymorphicValue(
          concreteType: reference,
          value: RecordValue(const {"field": StringValue("named")}),
        ),
        skir.TypedValue_kind.namedWrapper,
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
      skir.DataPathSegment_kind.fieldWrapper,
      skir.DataPathSegment_kind.indexWrapper,
      skir.DataPathSegment_kind.mapKeyWrapper,
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
    expect(encoded.typeId.kind, skir.TypeId_kind.builtinWrapper);
    expect(
      (encoded.typeId as skir.TypeId_builtinWrapper).value.kind,
      skir.BuiltinTypeId_kind.optionConst,
    );
    expect(encoded.revision, 1);
    expect(encoded.arguments, hasLength(1));

    expect(
      encoded.arguments.single.kind,
      skir.TypeExpression_kind.namedWrapper,
    );

    expect(codec.decodeType(encoded).valueOrNull, generic);
  });

  test("preserves every binding outcome field on the wire", () {
    final path = codec.encodePath(DataPath.root).valueOrNull!;
    final binding = skir.BindingRef(
      bindingId: skir.BindingId(value: 1),
      path: path,
    );
    final outcomes = <skir.BindingResolution>[
      skir.BindingResolution.createResolved(
        reference: binding,
        valueType: codec.typeCodec
            .encodeExpression(const StringType())
            .valueOrNull!,
        value: skir.TypedValue.wrapString("value"),
        writable: true,
        revision: 2,
      ),
      skir.BindingResolution.wrapDiagnostics([
        skir.TypeDiagnostic(
          code: skir.DiagnosticCode.invalidPath,
          severity: skir.DiagnosticSeverity.error,
          message: "Invalid binding",
          path: path,
          relatedType: null,
          details: const [],
        ),
      ]),
    ];
    expect(outcomes[0].kind, skir.BindingResolution_kind.resolvedWrapper);
    final resolved =
        (outcomes[0] as skir.BindingResolution_resolvedWrapper).value;
    expect(resolved.reference, binding);

    expect(resolved.valueType.kind, skir.TypeExpression_kind.stringWrapper);
    expect(resolved.value, skir.TypedValue.wrapString("value"));
    expect(resolved.writable, isTrue);
    expect(resolved.revision, 2);

    expect(outcomes[1].kind, skir.BindingResolution_kind.diagnosticsWrapper);
    final diagnostics =
        (outcomes[1] as skir.BindingResolution_diagnosticsWrapper).value;
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.code, skir.DiagnosticCode.invalidPath);
    expect(diagnostics.single.message, "Invalid binding");
  });
}

final _one = IntegerValue(BigInt.one);
