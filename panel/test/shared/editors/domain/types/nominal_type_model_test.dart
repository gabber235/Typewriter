import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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

  test("registry bootstraps option variants and standard nominal types", () {
    final registry = TypeRegistry(TypeCatalog(const []));
    final option = registry.resolveExact(
      standardTypeRefs.optionOf(const StringType()),
    );
    final someReference = standardTypeRefs.someOf(const StringType());
    final some = registry.resolveExact(someReference);

    expect(option.valueOrNull!.kind, NominalTypeKind.sealedAbstract);
    expect(some.valueOrNull!.kind, NominalTypeKind.concrete);
    expect(
      some.valueOrNull!.ancestors,
      contains(standardTypeRefs.optionOf(const StringType())),
    );
    expect(registry.resolveExact(standardTypeRefs.color).diagnostics, isEmpty);
    expect(
      registry.resolveExact(standardTypeRefs.iconifyIcon).diagnostics,
      isEmpty,
    );
    expect(
      registry.resolveExact(standardTypeRefs.svgIcon).diagnostics,
      isEmpty,
    );
    expect(
      registry.resolveExact(standardTypeRefs.icon).valueOrNull!.kind,
      NominalTypeKind.sealedAbstract,
    );
    expect(
      registry
          .resolveExact(standardTypeRefs.iconifyIcon)
          .valueOrNull!
          .ancestors,
      contains(standardTypeRefs.icon),
    );
    expect(
      registry.resolveExact(standardTypeRefs.svgIcon).valueOrNull!.ancestors,
      contains(standardTypeRefs.icon),
    );
    expect(
      registry
          .resolveExact(standardTypeRefs.refTo(const StringType()))
          .diagnostics,
      isEmpty,
    );
    expect(
      registry.definition(standardTypeRefs.color)!.defaultPresentationId,
      standardColorPresentationId,
    );
    expect(
      registry.definition(standardTypeRefs.iconifyIcon)!.defaultPresentationId,
      standardIconifyPresentationId,
    );
    expect(
      registry.definition(standardTypeRefs.svgIcon)!.defaultPresentationId,
      standardSvgIconPresentationId,
    );

    final color = registry.definition(standardTypeRefs.color)!;
    expect(color.representation, isA<IntegerType>());
    expect(
      (color.representation as IntegerType).width,
      IntegerWidth.unsigned32,
    );
    expect(
      IntegerValue(
        (BigInt.one << 32) - BigInt.one,
      ).validateAgainst(NamedType(standardTypeRefs.color), registry: registry),
      isEmpty,
    );
    expect(
      IntegerValue(
        BigInt.one << 32,
      ).validateAgainst(NamedType(standardTypeRefs.color), registry: registry),
      isNotEmpty,
    );
  });

  test("standard icon validates exact concrete icon descendants", () {
    final registry = TypeRegistry(TypeCatalog(const []));
    final icon = NamedType(standardTypeRefs.icon);

    expect(
      PolymorphicValue(
        concreteType: standardTypeRefs.iconifyIcon,
        value: const StringValue("mdi:account"),
      ).validateAgainst(icon, registry: registry),
      isEmpty,
    );
    expect(
      PolymorphicValue(
        concreteType: standardTypeRefs.svgIcon,
        value: const StringValue("<svg><script>run()</script></svg>"),
      ).validateAgainst(icon, registry: registry),
      isNotEmpty,
    );
    expect(
      PolymorphicValue(
        concreteType: standardTypeRefs.color,
        value: IntegerValue(BigInt.zero),
      ).validateAgainst(icon, registry: registry),
      isNotEmpty,
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
    final registry = TypeRegistry(TypeCatalog(const []));
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
