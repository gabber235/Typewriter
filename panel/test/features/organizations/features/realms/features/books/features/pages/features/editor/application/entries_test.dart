import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  group("EntryDragPayload", () {
    test("participates in graph movement and grouped reference drops", () {
      const primary = EntryIdentifier(
        "first",
        pageId: "page",
        elementType: _sourceEntryType,
      );
      const second = EntryIdentifier(
        "second",
        pageId: "page",
        elementType: _targetEntryType,
      );
      final payload = EntryDragPayload(
        primary: primary,
        entries: [primary, second],
      );

      expect(payload, isA<GraphDragData>());
      expect(payload.graphId, primary);
      expect((payload as Object).referenceResources, [primary, second]);
      expect((primary as Object).referenceResources, [primary]);
    });
  });

  group("ElementDefinition", () {
    test("derives qualified identity from its root type", () {
      final definition = _elementDefinition();

      expect(definition.typeId, _rootType.id);
      expect(definition.namespace, _rootTypeId);
      expect(definition.qualifiedName, _rootTypeId);
    });

    test("derives deprecation state from its metadata", () {
      final deprecated = _elementDefinition(
        deprecation: const ElementDeprecation(reason: "Use another type"),
      );

      expect(_elementDefinition().isDeprecated, isFalse);
      expect(deprecated.isDeprecated, isTrue);
      expect(deprecated.deprecation?.reason, "Use another type");
    });

    test("resolves a concrete record root", () {
      final result = _elementDefinition().resolve(
        _registry(
          kind: NominalTypeKind.concrete,
          type: RecordType(fields: {}),
        ),
      );

      expect(result.valueOrNull?.reference, _rootType);
    });

    test("reports unknown, abstract, and nonrecord roots", () {
      final unknown = _elementDefinition().resolve(
        TypeRegistry(TypeCatalog([])),
      );
      final abstract = _elementDefinition().resolve(
        _registry(
          kind: NominalTypeKind.openAbstract,
          type: RecordType(fields: {}),
        ),
      );
      final nonrecord = _elementDefinition().resolve(
        _registry(kind: NominalTypeKind.concrete, type: const StringType()),
      );

      expect(unknown.diagnostics.single.code, TypeDiagnosticCode.unknownType);
      expect(
        abstract.diagnostics.single.code,
        TypeDiagnosticCode.invalidConcreteType,
      );
      expect(
        nonrecord.diagnostics.single.code,
        TypeDiagnosticCode.incompatibleRepresentation,
      );
    });

    test("catalogue readiness gates entry and cue selection creation", () {
      final definition = _elementDefinition();
      final catalog = TypeCatalog([
        TypeDefinition(
          id: _rootType,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {}),
        ),
      ]);
      final snapshot = RealmEditorCatalogSnapshot(
        catalog: catalog,
        generation: const CatalogGeneration("1"),
      );
      final ready =
          AsyncValue<RealmEditorCatalogState>.data(
            RealmEditorCatalogState.ready(snapshot),
          ).resolveElement(
            definition,
            (resolvedCatalog, presentations) => resolvedCatalog,
          );
      final loading =
          const AsyncValue<RealmEditorCatalogState>.data(
            RealmEditorCatalogState.loading(),
          ).resolveElement(
            definition,
            (resolvedCatalog, presentations) => resolvedCatalog,
          );

      expect(ready.requireValue.definitions, isNotEmpty);
      expect(loading, isA<AsyncLoading<TypeCatalog>>());
    });

    test("catalogue resolution rejects missing presentation dependencies", () {
      const missingId = PresentationId(namespace: "example", name: "editor");
      final snapshot = RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([
          TypeDefinition(
            id: _rootType,
            kind: NominalTypeKind.concrete,
            representation: RecordType(fields: {}),
            defaultPresentationId: missingId,
          ),
        ]),
        generation: const CatalogGeneration("1"),
      );

      final result =
          AsyncValue<RealmEditorCatalogState>.data(
            RealmEditorCatalogState.ready(snapshot),
          ).resolveElement(
            _elementDefinition(),
            (catalog, presentations) => catalog,
          );

      expect(result, isA<AsyncError<TypeCatalog>>());
      final exception = result.error! as ElementDefinitionException;
      expect(
        exception.diagnostics.single.code,
        TypeDiagnosticCode.invalidPresentation,
      );
      expect(
        exception.diagnostics.single.message,
        "Realm catalog omitted required presentations: example/editor",
      );
    });
  });

  group("Entry geometry and identity", () {
    test("calculates centers and squared distance", () {
      const first = EntryPlacement(x: 0, y: 0, width: 100, height: 100);
      const second = EntryPlacement(x: 100, y: 0, width: 100, height: 100);

      expect(first.center, const Offset(50, 50));
      expect(first.distanceSquaredTo(second), 10000);
    });

    test("preserves timeline entry placement through serialization", () {
      const placement = EntryPlacement(
        x: 3,
        y: 0,
        width: 1,
        height: 1,
        kind: EntryPlacementKind.timelineEntry,
      );

      expect(EntryPlacement.fromJson(placement.toJson()), placement);
    });

    test("exposes the identifier for every page entry state", () {
      final definition = EntryDefinition(
        id: "defined",
        elementDefinition: _elementDefinition(),
        placement: const EntryPlacement(x: 0, y: 0, width: 10, height: 10),
        data: RecordValue(const {
          "id": StringValue("defined"),
          "name": StringValue("Defined"),
        }),
        inwardEdges: const [],
        outwardEdges: const [],
      );

      expect(PageEntry.definition(definition: definition).id, "defined");
      expect(
        PageEntry.reference(
          id: "reference",
          name: "Reference",
          elementDefinition: _elementDefinition(),
          pageId: "page",
        ).id,
        "reference",
      );
      expect(const PageEntry.nonexistent(id: "missing").id, "missing");
      expect(
        PageEntry.missingElementDefinition(
          id: "unknown",
          name: "Unknown",
          placement: const EntryPlacement(x: 0, y: 0, width: 10, height: 10),
          inwardLinks: const [],
          outwardLinks: const [],
        ).id,
        "unknown",
      );
    });
  });

  group("Entry reference drops", () {
    final registry = _referenceDropRegistry();
    final source = EntryDefinition(
      id: "source",
      elementDefinition: _elementDefinition(rootType: _sourceEntryType),
      placement: const EntryPlacement(x: 0, y: 0, width: 10, height: 10),
      data: RecordValue({
        "id": const StringValue("source"),
        "name": const StringValue("Source"),
        "child": ReferenceValue(recordId("element:previous")),
      }),
      inwardEdges: const [],
      outwardEdges: const [],
    );
    final target = EntryDefinition(
      id: "target",
      elementDefinition: _elementDefinition(rootType: _targetEntryType),
      placement: const EntryPlacement(x: 20, y: 0, width: 10, height: 10),
      data: RecordValue(const {
        "id": StringValue("target"),
        "name": StringValue("Target"),
      }),
      inwardEdges: const [],
      outwardEdges: const [],
    );

    test("derives the update from the dragged source", () {
      const targetIdentity = EntryIdentifier(
        "target",
        elementType: _targetEntryType,
      );
      expect(registry.resolveExact(_sourceEntryType).diagnostics, isEmpty);
      expect(targetIdentity.isAcceptedBy(_targetEntryType, registry), isTrue);
      final values = source.referenceDropValues(targetIdentity, registry);

      expect(values, {
        DataPath.root.field("child"): ReferenceValue(
          recordId("element:target"),
        ),
      });
    });

    test("does not derive the reverse update from the drop target", () {
      final values = target.referenceDropValues(
        const EntryIdentifier("source", elementType: _sourceEntryType),
        registry,
      );

      expect(values, isEmpty);
    });

    test("rejects a target outside the source reference type", () {
      final values = source.referenceDropValues(
        const EntryIdentifier("other", elementType: _otherEntryType),
        registry,
      );

      expect(values, isEmpty);
    });
  });

  test("entry presentation always starts with the editable name", () {
    const presentationId = PresentationId(namespace: "example", name: "editor");
    const rootBinding = BindingReference(bindingId: BindingId(0));
    final catalog = TypeCatalog([
      TypeDefinition(
        id: _rootType,
        kind: NominalTypeKind.concrete,
        representation: RecordType(
          fields: const {
            "id": TypeField(name: "id", type: StringType()),
            "name": TypeField(name: "name", type: StringType()),
            "message": TypeField(name: "message", type: StringType()),
          },
        ),
        defaultPresentationId: presentationId,
      ),
    ]);
    final presentation = PresentationDefinition.single(
      id: presentationId,
      target: NamedType(_rootType),
      root: PresentationNode(
        id: "message",
        element: TextInputElement(
          control: BoundControl(
            binding: rootBinding.at(DataPath.root.field("message")),
            label: "Message".asStringLiteral,
          ),
          multiline: false,
        ),
      ),
    );
    final value = RecordValue(const {
      "id": StringValue("entry"),
      "name": StringValue("Entry name"),
      "message": StringValue("Hello"),
    });
    final target = fakeEditorTarget(
      targetId: "entry",
      label: "Entry name",
      document: EditorDocument(
        rootType: RecordType(
          fields: {
            "value": TypeField(name: "value", type: NamedType(_rootType)),
          },
        ),
        typeCatalog: catalog,
        confirmedValue: RecordValue({"value": value}),
        revision: 1,
      ),
      commit: (commit) async =>
          MutationSuccess(revision: 2, value: commit.rootValue),
    );
    final selection = EntrySelection(
      target: target,
      id: const EntryIdentifier("entry", pageId: "page"),
      definition: EntryDefinition(
        id: "entry",
        elementDefinition: _elementDefinition(),
        placement: const EntryPlacement(x: 0, y: 0, width: 10, height: 10),
        data: value,
        inwardEdges: const [],
        outwardEdges: const [],
      ),
      typeCatalog: catalog,
      presentations: [presentation],
      selectionCapabilities: const [],
    );
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);

    final model = selection.buildPresentation(owners);
    final children = (model.root.element as ColumnElement).children;
    final name = children.first.element as TypedFieldElement;

    expect(name.binding, rootBinding.at(DataPath.root.field("name")));
    expect(name.expectedType, const StringType());
    expect(children.last.element, isA<PresentationInvocationElement>());
  });
}

ElementDefinition _elementDefinition({
  ElementDeprecation? deprecation,
  ResolvedTypeRef? rootType,
}) => ElementDefinition(
  rootType: rootType ?? _rootType,
  name: "Example",
  description: "Typed entry",
  color: Colors.blue,
  icon: const IconValue.iconify("fa-solid:star"),
  deprecation: deprecation,
);

TypeRegistry _registry({
  required NominalTypeKind kind,
  required TypeExpression type,
}) => TypeRegistry(
  TypeCatalog([
    TypeDefinition(id: _rootType, kind: kind, representation: type),
  ]),
);

final _rootType = ResolvedTypeRef(id: DeclaredTypeId(_rootTypeId), revision: 1);

const _sourceEntryType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "example", name: "SourceEntry"),
  revision: 1,
);
const _targetEntryType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "example", name: "TargetEntry"),
  revision: 1,
);
const _otherEntryType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "example", name: "OtherEntry"),
  revision: 1,
);

TypeRegistry _referenceDropRegistry() => TypeRegistry(
  TypeCatalog([
    ...referenceResourceTypes.definitions,
    TypeDefinition(
      id: _sourceEntryType,
      kind: NominalTypeKind.concrete,
      representation: RecordType(
        fields: {
          "child": TypeField(
            name: "child",
            type: const ReferenceType(target: _targetEntryType),
          ),
        },
      ),
    ),
    TypeDefinition(
      id: _targetEntryType,
      kind: NominalTypeKind.concrete,
      parents: [referenceResourceTypes.element],
    ),
    TypeDefinition(
      id: _otherEntryType,
      kind: NominalTypeKind.concrete,
      parents: [referenceResourceTypes.element],
    ),
  ]),
);

const _rootTypeId = "0123456789abcdef0123456789abcdef";
