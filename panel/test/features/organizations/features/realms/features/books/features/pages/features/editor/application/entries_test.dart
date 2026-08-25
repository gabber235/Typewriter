import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
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
        name: "Defined",
        elementDefinition: _elementDefinition(),
        placement: const EntryPlacement(x: 0, y: 0, width: 10, height: 10),
        data: RecordValue(const {}),
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
}

ElementDefinition _elementDefinition({ElementDeprecation? deprecation}) =>
    ElementDefinition(
      rootType: _rootType,
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

const _rootTypeId = "0123456789abcdef0123456789abcdef";
