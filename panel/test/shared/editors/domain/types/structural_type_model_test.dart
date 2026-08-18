import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("enum JSON preserves its explicit value type", () {
    final type = EnumType(
      valueType: const StringType(minimumLength: 1),
      values: const [StringValue("open"), StringValue("closed")],
    );
    const converter = TypeExpressionJsonConverter();
    final encoded = converter.toJson(type);
    final decoded = converter.fromJson(encoded);

    expect(typeExpressionsEqual(decoded, type), isTrue);
    expect(encoded["valueType"], isA<Map<String, Object?>>());
  });

  test("records are complete and enums accept only declared values", () {
    final record = RecordType(
      fields: {
        "state": TypeField(
          name: "state",
          type: EnumType(
            valueType: const StringType(),
            values: const [StringValue("open"), StringValue("closed")],
          ),
        ),
      },
    );

    expect(
      RecordValue({}).validateAgainst(record).single.code,
      TypeDiagnosticCode.missingField,
    );
    expect(
      RecordValue({"state": const StringValue("open")}).validateAgainst(record),
      isEmpty,
    );
    expect(
      RecordValue({
        "state": const StringValue("unknown"),
      }).validateAgainst(record),
      isNotEmpty,
    );
  });

  test("generic inference produces an exact validated application", () {
    final box = _ref("Box");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: box,
          kind: NominalTypeKind.concrete,
          parameters: const [TypeParameter(name: "T")],
          representation: RecordType(
            fields: const {
              "value": TypeField(name: "value", type: ParameterType("T")),
            },
          ),
        ),
      ]),
    );
    final inferred = box.inferFrom(
      RecordType(
        fields: const {"value": TypeField(name: "value", type: BooleanType())},
      ),
      registry,
    );

    expect(inferred.valueOrNull, box.withArguments(const [BooleanType()]));
  });

  test("multiple inheritance intersects constraints without precedence", () {
    final broad = _ref("Broad");
    final narrow = _ref("Narrow");
    final child = _ref("Child");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: broad,
          kind: NominalTypeKind.openAbstract,
          representation: const StringType(minimumLength: 1, maximumLength: 10),
        ),
        TypeDefinition(
          id: narrow,
          kind: NominalTypeKind.openAbstract,
          representation: const StringType(minimumLength: 2, maximumLength: 8),
        ),
        TypeDefinition(
          id: child,
          kind: NominalTypeKind.concrete,
          parents: [broad, narrow],
        ),
      ]),
    );
    final resolved = registry.resolveExact(child).valueOrNull!;

    expect(
      typeExpressionsEqual(
        resolved.representation,
        const StringType(minimumLength: 2, maximumLength: 8),
      ),
      isTrue,
    );
  });

  test("safe refinement rejects a weakened inherited constraint", () {
    final parent = _ref("Parent");
    final child = _ref("Child");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: parent,
          kind: NominalTypeKind.openAbstract,
          representation: const StringType(minimumLength: 3),
        ),
        TypeDefinition(
          id: child,
          kind: NominalTypeKind.concrete,
          parents: [parent],
          representation: const StringType(minimumLength: 1),
        ),
      ]),
    );

    expect(
      registry.resolveExact(child).diagnostics.single.code,
      TypeDiagnosticCode.conflictingInheritance,
    );
  });

  test(
    "duration values and constraints require exact millisecond precision",
    () {
      const type = DurationType(maximum: Duration(milliseconds: 5));
      const invalidType = DurationType(maximum: Duration(microseconds: 5001));

      expect(
        (const DurationValue(Duration(milliseconds: 1))).validateAgainst(type),
        isEmpty,
      );
      expect(
        (const DurationValue(
          Duration(microseconds: 1001),
        )).validateAgainst(type),
        isNotEmpty,
      );
      expect(invalidType.validateConstraints(const {}), isNotEmpty);
    },
  );

  test("named enum values defer validation until registry resolution", () {
    final valueType = _ref("statusValue");
    final validEnum = _ref("validStatus");
    final invalidEnum = _ref("invalidStatus");
    final registry = TypeRegistry(
      TypeCatalog([
        TypeDefinition(
          id: valueType,
          kind: NominalTypeKind.concrete,
          representation: const StringType(),
        ),
        TypeDefinition(
          id: validEnum,
          kind: NominalTypeKind.concrete,
          representation: EnumType(
            valueType: NamedType(valueType),
            values: const [StringValue("open")],
          ),
        ),
        TypeDefinition(
          id: invalidEnum,
          kind: NominalTypeKind.concrete,
          representation: EnumType(
            valueType: NamedType(valueType),
            values: const [BooleanValue(true)],
          ),
        ),
      ]),
    );

    expect(registry.resolveExact(validEnum).diagnostics, isEmpty);
    expect(registry.resolveExact(invalidEnum).diagnostics, isNotEmpty);
  });
}

ResolvedTypeRef _ref(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test/v1", name: name),
  revision: 1,
);
