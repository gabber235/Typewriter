import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Value validation", () {
    test("integer width boundaries are inclusive", () {
      const type = IntegerType(width: IntegerWidth.signed8);

      expect(IntegerValue(BigInt.from(-128)).validateAgainst(type), isEmpty);
      expect(IntegerValue(BigInt.from(127)).validateAgainst(type), isEmpty);
      expect(
        IntegerValue(BigInt.from(128)).validateAgainst(type).single.code,
        TypeDiagnosticCode.invalidValue,
      );
    });

    test("string length counts Unicode scalar values and applies patterns", () {
      const type = StringType(
        minimumLength: 2,
        maximumLength: 2,
        patterns: [r"^..$"],
      );

      expect((const StringValue("日本")).validateAgainst(type), isEmpty);
      expect(
        (const StringValue(
          "日",
        )).validateAgainst(type).map((diagnostic) => diagnostic.message),
        contains(contains("at least 2")),
      );
    });

    test("list validation reports uniqueness and nested index paths", () {
      const type = ListType(
        element: IntegerType(width: IntegerWidth.unsigned8),
        unique: true,
      );
      final value = ListValue([
        IntegerValue(BigInt.one),
        IntegerValue(BigInt.from(-1)),
        IntegerValue(BigInt.one),
      ]);

      final diagnostics = value.validateAgainst(type);

      expect(diagnostics, hasLength(2));
      expect(diagnostics.first.message, contains("unique"));
      expect(diagnostics.last.path, DataPath.root.index(1));
    });

    test("records require explicit option values for optional fields", () {
      final registry = TypeRegistry(TypeCatalog([]));
      final type = RecordType(
        fields: {
          "required": const TypeField(name: "required", type: StringType()),
          "optional": TypeField(
            name: "optional",
            type: NamedType(standardTypeRefs.optionOf(const StringType())),
          ),
        },
      );

      final diagnostics = RecordValue({
        "optional": PolymorphicValue(
          concreteType: standardTypeRefs.noneOf(const StringType()),
          value: const UnitValue(),
        ),
      }).validateAgainst(type, registry: registry);

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.code, TypeDiagnosticCode.missingField);
      expect(diagnostics.single.path, DataPath.root.field("required"));
    });

    test(
      "closed records reject unknown fields while open records accept them",
      () {
        final value = RecordValue({"extra": const BooleanValue(true)});
        final closed = RecordType(fields: {});
        final open = RecordType(fields: {}, closed: false);

        expect(
          value.validateAgainst(closed).single.code,
          TypeDiagnosticCode.unknownField,
        );
        expect(value.validateAgainst(open), isEmpty);
      },
    );

    test("map diagnostics retain the typed key path", () {
      final key = IntegerValue(BigInt.one);
      final value = MapValue([
        DataMapEntry(key: key, value: const StringValue("wrong")),
      ]);
      const type = MapType(key: AnyType(), value: BooleanType());

      final diagnostics = value.validateAgainst(type);

      expect(diagnostics.single.path, DataPath.root.mapKey(key));
      expect(diagnostics.single.code, TypeDiagnosticCode.invalidValue);
    });

    test("polymorphic validation checks the concrete representation", () {
      final parent = ResolvedTypeRef(
        id: const QualifiedTypeId(namespace: "test", name: "Value"),
        revision: 1,
      );
      final child = ResolvedTypeRef(
        id: const QualifiedTypeId(namespace: "test", name: "Count"),
        revision: 1,
      );
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(id: parent, kind: NominalTypeKind.sealedAbstract),
          TypeDefinition(
            id: child,
            kind: NominalTypeKind.concrete,
            parents: [parent],
            representation: const IntegerType(width: IntegerWidth.unsigned8),
          ),
        ]),
      );
      final value = PolymorphicValue(
        concreteType: child,
        value: IntegerValue(BigInt.from(-1)),
      );

      final diagnostics = value.validateAgainst(
        NamedType(parent),
        registry: registry,
      );

      expect(diagnostics.single.path, DataPath.root);
    });

    test("float values must be finite and within constraints", () {
      const type = FloatType(width: FloatWidth.float64, minimum: 0, maximum: 1);

      expect((const FloatValue(0.5)).validateAgainst(type), isEmpty);
      expect(
        (const FloatValue(double.nan)).validateAgainst(type).single.message,
        contains("finite"),
      );
      expect(
        (const FloatValue(2)).validateAgainst(type).single.message,
        contains("at most"),
      );
    });
  });
}
