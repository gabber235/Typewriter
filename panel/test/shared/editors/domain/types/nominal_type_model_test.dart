import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "type identities distinguish builtins, qualifications, and revisions",
    () {
      const first = QualifiedTypeId(namespace: "example/v1", name: "Entry");
      const second = QualifiedTypeId(namespace: "example/v1", name: "Entry");
      final revisionOne = ResolvedTypeRef(id: first, revision: 1);
      final revisionTwo = ResolvedTypeRef(id: second, revision: 2);

      expect(first, second);
      expect(revisionOne, isNot(revisionTwo));
      expect(const TypeId.option(), isA<TypeId>());
      expect(
        const ConversionId(namespace: "example/v1", name: "convert"),
        const ConversionId(namespace: "example/v1", name: "convert"),
      );
    },
  );

  test(
    "frozen catalog identities and resolved references support copyWith",
    () {
      const presentation = PresentationId(namespace: "panel", name: "default");
      const conversion = ConversionId(namespace: "panel", name: "convert");
      const action = RealmActionId(namespace: "realm", name: "reload");
      const generation = CatalogGeneration("1");
      final reference = ResolvedTypeRef(id: const TypeId.option(), revision: 1);

      expect(presentation.copyWith(name: "compact").name, "compact");
      expect(conversion.copyWith(name: "project").name, "project");
      expect(action.copyWith(name: "callback").name, "callback");
      expect(generation.copyWith(value: "2"), const CatalogGeneration("2"));
      expect(reference.copyWith(revision: 2).revision, 2);
    },
  );

  test("type definitions preserve immutable presentation links", () {
    const fallback = PresentationId(namespace: "panel", name: "fallback");
    const compact = PresentationId(namespace: "panel", name: "compact");
    final definition = TypeDefinition(
      id: _ref("Presented"),
      kind: NominalTypeKind.concrete,
      defaultPresentationId: fallback,
      namedPresentations: const {"compact": compact},
    );

    expect(definition.defaultPresentationId, fallback);
    expect(definition.namedPresentations, {"compact": compact});
    expect(
      () => definition.namedPresentations["other"] = fallback,
      throwsUnsupportedError,
    );
    expect(
      definition
          .copyWith(namedPresentations: const {"other": fallback})
          .namedPresentations,
      {"other": fallback},
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
