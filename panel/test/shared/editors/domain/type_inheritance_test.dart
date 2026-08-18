import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("TypeRegistry", () {
    test("multiple inheritance intersects independent record constraints", () {
      final named = _revision("named");
      final bounded = _revision("bounded");
      final child = _revision("child");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: named,
            representation: RecordType(
              fields: {
                "name": const TypeField(name: "name", type: StringType()),
              },
            ),
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: bounded,
            representation: RecordType(
              fields: {
                "count": TypeField(
                  name: "count",
                  type: IntegerType(
                    width: IntegerWidth.signed32,
                    minimum: BigInt.zero,
                  ),
                ),
              },
            ),
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: child,
            representation: RecordType(
              fields: {
                "enabled": const TypeField(
                  name: "enabled",
                  type: BooleanType(),
                ),
              },
            ),
            parents: [named, bounded],
          ),
        ]),
      );

      final result = registry.resolve(NamedType(child));
      final representation = result.valueOrNull!.representation as RecordType;

      expect(
        representation.fields.keys,
        containsAll(["name", "count", "enabled"]),
      );
      expect(result.valueOrNull!.ancestors, {named, bounded});
    });

    test("conflicting inherited field representations are rejected", () {
      final left = _revision("left");
      final right = _revision("right");
      final child = _revision("conflict");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: left,
            representation: _recordField("value", const StringType()),
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: right,
            representation: _recordField("value", const BooleanType()),
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: child,
            representation: RecordType(fields: {}),
            parents: [left, right],
          ),
        ]),
      );

      final result = registry.resolve(NamedType(child));

      expect(result, isA<TypeFailure<ResolvedType>>());
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(TypeDiagnosticCode.conflictingInheritance),
      );
    });

    test("a child cannot weaken an inherited constraint", () {
      final parent = _revision("constrained_parent");
      final child = _revision("weakened_child");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: parent,
            representation: _recordField(
              "name",
              const StringType(minimumLength: 3),
            ),
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: child,
            representation: _recordField("name", const StringType()),
            parents: [parent],
          ),
        ]),
      );

      final result = registry.resolve(NamedType(child));

      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.conflictingInheritance,
      );
    });

    test("inheritance cycles are diagnosed", () {
      final first = _revision("first");
      final second = _revision("second");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: first,
            representation: const AnyType(),
            parents: [second],
          ),
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: second,
            representation: const AnyType(),
            parents: [first],
          ),
        ]),
      );

      final result = registry.resolve(NamedType(first));

      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.inheritanceCycle,
      );
    });
  });
}

ResolvedTypeRef _revision(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);

RecordType _recordField(
  String name,
  TypeExpression type, {
  DataValue? initialValue,
}) => RecordType(
  fields: {name: TypeField(name: name, type: type, initialValue: initialValue)},
);
