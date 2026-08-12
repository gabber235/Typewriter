import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("constraint declarations", () {
    test("validates patterns and collection lengths", () {
      final diagnostics = RecordType(
        fields: {
          "text": const TypeField(
            name: "text",
            type: StringType(
              minimumLength: 4,
              maximumLength: 2,
              patterns: ["["],
            ),
          ),
          "bytes": const TypeField(
            name: "bytes",
            type: BytesType(minimumLength: -1),
          ),
          "items": const TypeField(
            name: "items",
            type: ListType(
              element: BooleanType(),
              minimumLength: 3,
              maximumLength: 1,
            ),
          ),
          "map": const TypeField(
            name: "map",
            type: MapType(
              key: StringType(),
              value: BooleanType(),
              maximumLength: -1,
            ),
          ),
        },
      )._validateDeclaration();

      expect(
        diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          contains("String length bounds"),
          contains("String pattern"),
          contains("Byte length minimum"),
          contains("List length bounds"),
          contains("Map length maximum"),
        ]),
      );
    });

    test("validates numeric bounds and widths", () {
      final diagnostics = RecordType(
        fields: {
          "integer": TypeField(
            name: "integer",
            type: IntegerType(
              width: IntegerWidth.signed8,
              minimum: BigInt.from(200),
              maximum: BigInt.from(100),
            ),
          ),
          "float": const TypeField(
            name: "float",
            type: FloatType(
              width: FloatWidth.float32,
              minimum: 4e38,
              maximum: double.infinity,
            ),
          ),
          "decimal": const TypeField(
            name: "decimal",
            type: DecimalType(
              minimum: "9007199254740993.1",
              maximum: "9007199254740993.01",
              scale: 1,
            ),
          ),
        },
      )._validateDeclaration();

      expect(
        diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          contains("Integer minimum exceeds"),
          contains("Integer bounds"),
          contains("Float minimum exceeds"),
          contains("Float maximum must be finite"),
          contains("Decimal bounds"),
          contains("Decimal maximum exceeds its scale"),
        ]),
      );
    });

    test("validates decimal syntax and temporal bounds", () {
      final diagnostics = RecordType(
        fields: {
          "decimal": const TypeField(
            name: "decimal",
            type: DecimalType(minimum: "01", scale: -1),
          ),
          "timestamp": TypeField(
            name: "timestamp",
            type: TimestampType(
              minimum: DateTime.utc(2026, 2),
              maximum: DateTime.utc(2026, 1),
            ),
          ),
          "duration": const TypeField(
            name: "duration",
            type: DurationType(
              minimum: Duration(seconds: 2),
              maximum: Duration(seconds: 1),
            ),
          ),
        },
      )._validateDeclaration();

      expect(
        diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          contains("Decimal scale must"),
          contains("Decimal minimum is malformed"),
          contains("Timestamp bounds"),
          contains("Duration bounds"),
        ]),
      );
    });

    test("validates record metadata and initial values", () {
      final diagnostics = RecordType(
        fields: {
          "": const TypeField(name: "wrong", type: BooleanType()),
          "count": const TypeField(
            name: "other",
            type: BooleanType(),
            initialValue: StringValue("invalid"),
          ),
        },
      )._validateDeclaration();

      expect(
        diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          contains("Record field name is empty"),
          contains("Record field metadata"),
          contains("StringValue is not valid"),
        ]),
      );
      expect(
        diagnostics.where(
          (diagnostic) => diagnostic.path.toString() == r"$.count",
        ),
        hasLength(2),
      );
    });
  });

  group("type declarations", () {
    test("validates duplicate, unknown, and recursive parameters", () {
      final definition = TypeDefinition(
        id: _revision("generic"),
        kind: NominalTypeKind.concrete,
        representation: const ParameterType("missing"),
        parameters: const [
          TypeParameter(name: "left", bound: ParameterType("right")),
          TypeParameter(name: "right", bound: ParameterType("left")),
          TypeParameter(name: "left"),
        ],
      );

      final diagnostics = definition.validateDeclaration();

      expect(
        diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          contains("duplicated"),
          contains("recursion"),
          contains("missing"),
        ]),
      );
      expect(
        diagnostics.every((diagnostic) => diagnostic.type == definition.id),
        isTrue,
      );
    });

    test("registry rejects malformed declarations before resolution", () {
      final id = _revision("invalid");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: id,
            kind: NominalTypeKind.concrete,
            representation: const StringType(patterns: ["["]),
          ),
        ]),
      );

      final result = registry.resolve(NamedType(id));

      expect(result, isA<TypeFailure<ResolvedType>>());
      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.invalidConstraint,
      );
      expect(result.diagnostics.single.type, id);
    });

    test("registry validates inherited declarations before resolution", () {
      final parent = _revision("invalidParent");
      final child = _revision("child");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: parent,
            kind: NominalTypeKind.concrete,
            representation: const StringType(patterns: ["["]),
          ),
          TypeDefinition(
            id: child,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
            parents: [parent],
          ),
        ]),
      );

      final result = registry.resolve(NamedType(child));

      expect(result, isA<TypeFailure<ResolvedType>>());
      expect(result.diagnostics.single.type, parent);
    });

    test("generic initial values defer until parameter substitution", () {
      final definition = TypeDefinition(
        id: _revision("initial"),
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: {
            "value": const TypeField(
              name: "value",
              type: ParameterType("valueType"),
              initialValue: StringValue("later"),
            ),
          },
        ),
        parameters: const [TypeParameter(name: "valueType")],
      );
      final diagnostics = definition.validateDeclaration();

      expect(diagnostics, isEmpty);
      expect(definition.validateDeclaration(), diagnostics);
    });
  });
}

extension on TypeExpression {
  List<TypeDiagnostic> _validateDeclaration() => validateConstraints(const {});
}

ResolvedTypeRef _revision(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "tests", name: name),
  revision: 1,
);
