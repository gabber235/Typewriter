import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("TypeRegistry", () {
    test("generic arguments substitute into the resolved representation", () {
      final box = _revision("box");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: box,
            parameters: [const TypeParameter(name: "T")],
            representation: RecordType(
              fields: {
                "value": const TypeField(
                  name: "value",
                  type: ParameterType("T"),
                ),
              },
            ),
          ),
        ]),
      );

      final result = registry.resolve(
        NamedType(box.withArguments([const BooleanType()])),
      );
      final record = result.valueOrNull!.representation as RecordType;

      expect(record.fields["value"]!.type, isA<BooleanType>());
    });

    test("generic arity and bounds return distinct diagnostics", () {
      final constrained = _revision("constrained");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: constrained,
            parameters: [
              const TypeParameter(
                name: "T",
                bound: StringType(minimumLength: 1),
              ),
            ],
            representation: const ParameterType("T"),
          ),
        ]),
      );

      final arity = registry.resolve(NamedType(constrained));
      final bound = registry.resolve(
        NamedType(constrained.withArguments([const BooleanType()])),
      );

      expect(arity.diagnostics.single.code, TypeDiagnosticCode.genericArity);
      expect(bound.diagnostics.single.code, TypeDiagnosticCode.genericBound);
    });

    test("duplicate and unknown definitions return structured diagnostics", () {
      final duplicate = _revision("duplicate");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: duplicate,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
          ),
          TypeDefinition(
            id: duplicate,
            kind: NominalTypeKind.concrete,
            representation: const StringType(),
          ),
        ]),
      );

      expect(
        registry.resolve(NamedType(duplicate)).diagnostics.single.code,
        TypeDiagnosticCode.duplicateDefinition,
      );
      expect(
        registry
            .resolve(NamedType(_revision("missing")))
            .diagnostics
            .single
            .code,
        TypeDiagnosticCode.unknownType,
      );
    });

    test("generic variance controls reference assignability", () {
      final invariant = _revision("invariant");
      final covariant = _revision("covariant");
      final contravariant = _revision("contravariant");
      final registry = TypeRegistry(
        TypeCatalog([
          _genericDefinition(invariant, TypeVariance.invariant),
          _genericDefinition(covariant, TypeVariance.covariant),
          _genericDefinition(contravariant, TypeVariance.contravariant),
        ]),
      );
      const narrow = StringType(minimumLength: 2, maximumLength: 4);
      const broad = StringType(minimumLength: 1, maximumLength: 8);

      expect(
        NamedType(invariant.withArguments([narrow])).isStructurallyAssignableTo(
          NamedType(invariant.withArguments([broad])),
          registry,
        ),
        isFalse,
      );
      expect(
        NamedType(covariant.withArguments([narrow])).isStructurallyAssignableTo(
          NamedType(covariant.withArguments([broad])),
          registry,
        ),
        isTrue,
      );
      expect(
        NamedType(
          contravariant.withArguments([broad]),
        ).isStructurallyAssignableTo(
          NamedType(contravariant.withArguments([narrow])),
          registry,
        ),
        isTrue,
      );
    });

    test("editable generic fields require invariant parameters", () {
      final id = _revision("invalid_variance");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            kind: NominalTypeKind.concrete,
            id: id,
            parameters: [
              const TypeParameter(name: "T", variance: TypeVariance.covariant),
            ],
            representation: RecordType(
              fields: {
                "value": const TypeField(
                  name: "value",
                  type: ParameterType("T"),
                ),
              },
            ),
          ),
        ]),
      );

      final result = registry.resolve(
        NamedType(id.withArguments(const [StringType()])),
      );

      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.varianceViolation,
      );
    });
  });
}

ResolvedTypeRef _revision(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);

TypeDefinition _genericDefinition(ResolvedTypeRef id, TypeVariance variance) =>
    TypeDefinition(
      kind: NominalTypeKind.concrete,
      id: id,
      parameters: [TypeParameter(name: "T", variance: variance)],
      representation: const ParameterType("T"),
    );
