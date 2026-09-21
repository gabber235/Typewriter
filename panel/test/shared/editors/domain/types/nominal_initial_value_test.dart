import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/realm_catalog_fixture.dart";

void main() {
  const container = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "Container"),
    revision: 1,
  );
  const string = StringType();
  TypeRegistry registry(DataValue initial) => TypeRegistry(
    receivedRealmCatalog([
      TypeDefinition(
        id: container,
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: {
            "optional": TypeField(
              name: "optional",
              type: NamedType(standardTypeRefs.optionOf(string)),
              initialValue: initial,
            ),
          },
        ),
      ),
    ]),
  );

  test("nominal field defaults resolve with the enclosing catalog", () {
    final initial = PolymorphicValue(
      concreteType: standardTypeRefs.noneOf(string),
      value: const UnitValue(),
    );
    final types = registry(initial);
    expect(types.resolveExact(container), isA<TypeSuccess<ResolvedType>>());
    expect(
      RecordValue({"optional": initial})
          .validateAgainst(NamedType(container), registry: types),
      isEmpty,
    );
  });

  test("invalid nominal defaults are rejected after resolution", () {
    final types = registry(const BooleanValue(true));
    final result = types.resolveExact(container);
    expect(result, isA<TypeFailure<ResolvedType>>());
    expect(
      result.diagnostics.map((issue) => issue.path),
      contains(DataPath.root.field("optional")),
    );
  });

  test("abstract fields require an explicit concrete descendant", () {
    final abstract = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "Abstract"),
      revision: 1,
    );
    final first = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "First"),
      revision: 1,
    );
    final second = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "Second"),
      revision: 1,
    );
    final root = ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "test", name: "Root"),
      revision: 1,
    );
    final types = TypeRegistry(
      TypeCatalog([
        TypeDefinition(id: abstract, kind: NominalTypeKind.sealedAbstract),
        TypeDefinition(
          id: first,
          kind: NominalTypeKind.concrete,
          parents: [abstract],
          representation: const RecordType(
            fields: {"value": TypeField(name: "value", type: StringType())},
          ),
        ),
        TypeDefinition(
          id: second,
          kind: NominalTypeKind.concrete,
          parents: [abstract],
          representation: const UnitType(),
        ),
        TypeDefinition(
          id: root,
          kind: NominalTypeKind.concrete,
          representation: RecordType(
            fields: {
              "choice": TypeField(name: "choice", type: NamedType(abstract)),
            },
          ),
        ),
      ]),
    );

    final draft = CreationDraft(rootType: NamedType(root), registry: types);
    addTearDown(draft.dispose);
    draft.selectConcreteType(DataPath.root.field("choice"), first);
    final result = draft.finalize();

    expect(
      result.valueOrNull,
      RecordValue({
        "choice": PolymorphicValue(
          concreteType: first,
          value: RecordValue({"value": const StringValue("")}),
        ),
      }),
    );
  });
}
