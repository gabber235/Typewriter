import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/realm_catalog_fixture.dart";

void main() {
  test("qualified type identities distinguish namespaces and revisions", () {
    const first = QualifiedTypeId(namespace: "example/v1", name: "Entry");
    const otherNamespace = QualifiedTypeId(
      namespace: "example/v2",
      name: "Entry",
    );

    expect(first, isNot(otherNamespace));
    expect(
      const ResolvedTypeRef(id: first, revision: 1),
      isNot(const ResolvedTypeRef(id: first, revision: 2)),
    );
  });

  test(
    "polymorphic values use exact concrete tags only at abstract boundaries",
    () {
      final animal = _ref("Animal");
      final dog = _ref("Dog");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: animal,
            kind: NominalTypeKind.openAbstract,
            representation: RecordType(
              fields: const {
                "name": TypeField(name: "name", type: StringType()),
              },
            ),
          ),
          TypeDefinition(
            id: dog,
            kind: NominalTypeKind.concrete,
            parents: [animal],
            representation: RecordType(
              fields: const {
                "breed": TypeField(name: "breed", type: StringType()),
              },
            ),
          ),
        ]),
      );
      final payload = RecordValue({
        "name": const StringValue("Milo"),
        "breed": const StringValue("Collie"),
      });
      final dogRepresentation =
          registry.resolveExact(dog).valueOrNull!.representation as RecordType;

      expect(dogRepresentation.fields.keys, containsAll(["name", "breed"]));
      expect(
        payload.validateAgainst(NamedType(dog), registry: registry),
        isEmpty,
      );
      expect(
        PolymorphicValue(
          concreteType: dog,
          value: payload,
        ).validateAgainst(NamedType(animal), registry: registry),
        isEmpty,
      );
      expect(
        PolymorphicValue(
          concreteType: ResolvedTypeRef(id: dog.id, revision: 2),
          value: payload,
        ).validateAgainst(NamedType(animal), registry: registry),
        isNotEmpty,
      );
      expect(
        PolymorphicValue(
          concreteType: dog,
          value: payload,
        ).validateAgainst(NamedType(dog), registry: registry).single.message,
        contains("must not carry a type tag"),
      );
    },
  );

  test("option initialization selects an exact none variant", () {
    final registry = TypeRegistry(receivedRealmCatalog());
    final option = NamedType(standardTypeRefs.optionOf(const StringType()));
    final result = option.createInitialValue(registry: registry);

    expect(
      result.valueOrNull,
      PolymorphicValue(
        concreteType: standardTypeRefs.noneOf(const StringType()),
        value: const UnitValue(),
      ),
    );
    expect(
      (result.valueOrNull!).validateAgainst(option, registry: registry),
      isEmpty,
    );
  });
}

ResolvedTypeRef _ref(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test/v1", name: name),
  revision: 1,
);
