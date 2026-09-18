import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = _referenceRegistry();
  const target = ResolvedTypeRef(
    id: TypeId.qualified(namespace: "example", name: "Entry"),
    revision: 1,
  );

  test("required references remain missing until edited", () {
    final draft = CreationDraft(
      rootType: const ReferenceType(target: target),
      registry: registry,
    );
    addTearDown(draft.dispose);

    expect(draft.value(DataPath.root), isA<MissingEditorValue>());
    expect(draft.finalize().valueOrNull, isNull);

    final reference = ReferenceValue(recordId("element:target"));
    expect(
      draft.update(DataPath.root, reference),
      isA<AppliedEditorMutation>(),
    );
    expect(draft.finalize().valueOrNull, reference);
  });

  test("lists start empty and use normal structural operations", () {
    final draft = CreationDraft(
      rootType: const ListType(
        element: ReferenceType(target: target),
        minimumLength: 2,
        unique: true,
      ),
      registry: registry,
    );
    addTearDown(draft.dispose);

    expect(draft.listStructure(DataPath.root)?.items, isEmpty);
    expect(draft.finalize().valueOrNull, isNull);

    expect(
      draft.update(
        DataPath.root,
        ListValue([ReferenceValue(recordId("element:first"))]),
      ),
      isA<AppliedEditorMutation>(),
    );
    expect(
      draft.value(DataPath.root).valueOrNull,
      ListValue([ReferenceValue(recordId("element:first"))]),
    );
    expect(draft.finalize().valueOrNull, isNull);

    draft
      ..appendListItem(DataPath.root)
      ..update(
        DataPath.root.index(1),
        ReferenceValue(recordId("element:second")),
      );

    expect(
      draft.finalize().valueOrNull,
      ListValue([
        ReferenceValue(recordId("element:first")),
        ReferenceValue(recordId("element:second")),
      ]),
    );
  });

  test(
    "map entries keep stable identity while key and value are incomplete",
    () {
      final draft = CreationDraft(
        rootType: const MapType(
          key: StringType(minimumLength: 1),
          value: ReferenceType(target: target),
          minimumLength: 1,
        ),
        registry: registry,
      );
      addTearDown(draft.dispose);

      draft.appendMapEntry(DataPath.root);
      final entry = draft.mapStructure(DataPath.root)!.entries.single;
      expect(entry.key, isA<MissingEditorValue>());
      expect(entry.value, isA<MissingEditorValue>());
      expect(entry.keyDiagnostics.single.message, "A value is required");
      expect(entry.valueDiagnostics.single.message, "A value is required");

      draft
        ..updateMapKey(DataPath.root, entry.id, const StringValue("key"))
        ..updateMapValue(
          DataPath.root,
          entry.id,
          ReferenceValue(recordId("element:value")),
        );

      expect(
        draft.finalize().valueOrNull,
        MapValue([
          DataMapEntry(
            key: const StringValue("key"),
            value: ReferenceValue(recordId("element:value")),
          ),
        ]),
      );
      final completed = draft.mapStructure(DataPath.root)!.entries.single;
      expect(completed.diagnostics, isEmpty);
    },
  );

  test("map collection diagnostics do not belong to individual entries", () {
    final draft = CreationDraft(
      rootType: const MapType(key: StringType(), value: StringType()),
      registry: registry,
    );
    addTearDown(draft.dispose);

    draft
      ..appendMapEntry(DataPath.root)
      ..appendMapEntry(DataPath.root);

    final structure = draft.mapStructure(DataPath.root)!;
    expect(structure.entries, hasLength(2));
    expect(structure.entries.expand((entry) => entry.diagnostics), isEmpty);
    expect(
      draft.finalize().diagnostics.map((diagnostic) => diagnostic.message),
      ["Map keys must be unique"],
    );
  });

  test("abstract selection creates an editable nested draft", () {
    const abstractType = ResolvedTypeRef(
      id: TypeId.qualified(namespace: "example", name: "Abstract"),
      revision: 1,
    );
    const concreteType = ResolvedTypeRef(
      id: TypeId.qualified(namespace: "example", name: "Concrete"),
      revision: 1,
    );
    final types = TypeRegistry(
      TypeCatalog([
        ...registry.catalog.definitions,
        const TypeDefinition(
          id: abstractType,
          kind: NominalTypeKind.openAbstract,
          representation: RecordType(fields: {}),
        ),
        const TypeDefinition(
          id: concreteType,
          kind: NominalTypeKind.concrete,
          parents: [abstractType],
          representation: RecordType(
            fields: {
              "target": TypeField(
                name: "target",
                type: ReferenceType(target: target),
              ),
            },
          ),
        ),
      ]),
    );
    final draft = CreationDraft(
      rootType: const NamedType(abstractType),
      registry: types,
    );
    addTearDown(draft.dispose);

    draft.selectConcreteType(DataPath.root, concreteType);
    expect(
      draft.concretePayloadValue(DataPath.root, DataPath.root.field("target")),
      isA<MissingEditorValue>(),
    );
    draft.updateConcretePayloadAt(
      DataPath.root,
      DataPath.root.field("target"),
      ReferenceValue(recordId("element:target")),
    );

    expect(draft.finalize().valueOrNull, isA<PolymorphicValue>());
  });

  test("fixed creation values can finalize without opening an editor", () {
    final fixed = ReferenceValue(recordId("element:fixed"));
    final result = materializeReadyValue(
      const ReferenceType(target: target),
      registry,
      fixedValues: {const MaterializationLocation.root(): fixed},
    );

    expect(result.valueOrNull, fixed);
  });
}

TypeRegistry _referenceRegistry() {
  const referenceable = ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.types",
      name: "Referenceable",
    ),
    revision: 1,
  );
  const element = ResolvedTypeRef(
    id: TypeId.qualified(
      namespace: "com.typewritermc.elements",
      name: "Element",
    ),
    revision: 1,
  );
  const target = ResolvedTypeRef(
    id: TypeId.qualified(namespace: "example", name: "Entry"),
    revision: 1,
  );
  return TypeRegistry(
    const TypeCatalog([
      TypeDefinition(id: referenceable, kind: NominalTypeKind.openAbstract),
      TypeDefinition(
        id: element,
        kind: NominalTypeKind.openAbstract,
        parents: [referenceable],
      ),
      TypeDefinition(
        id: target,
        kind: NominalTypeKind.concrete,
        parents: [element],
      ),
    ]),
  );
}
