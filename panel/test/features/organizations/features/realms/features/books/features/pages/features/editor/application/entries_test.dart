import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("ElementDefinition", () {
    test("uses resolved root identity and supports Freezed copyWith", () {
      final definition = _elementDefinition();
      final renamed = definition.copyWith(name: "Renamed");

      expect(definition.typeId, _rootType.id);
      expect(definition.namespace, "example");
      expect(definition.qualifiedName, "example::Entry");
      expect(renamed.name, "Renamed");
      expect(renamed.rootType, definition.rootType);
      expect(_elementDefinition(), definition);
    });

    test("stores deprecation directly", () {
      final definition = _elementDefinition(
        deprecation: const ElementDeprecation(reason: "Use another type"),
      );

      expect(definition.isDeprecated, isTrue);
      expect(definition.deprecation?.reason, "Use another type");
    });

    test("supports iconify and sanitized SVG icons", () {
      const iconify = IconValue.iconify("fa-solid:star");
      const svg = IconValue.svg('<svg viewBox="0 0 1 1"></svg>');

      expect(iconify.validate(), isEmpty);
      expect(svg.validate(), isEmpty);
      expect(iconify.typedValue.concreteType, standardTypeRefs.iconifyIcon);
      expect(svg.typedValue.concreteType, standardTypeRefs.svgIcon);
    });

    test("rejects unsafe SVG icons", () {
      const icon = IconValue.svg('<svg><script>alert("x")</script></svg>');

      expect(icon.validate().single.code, TypeDiagnosticCode.invalidValue);
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
      final ready = AsyncValue<RealmEditorCatalogState>.data(
        RealmEditorCatalogState.ready(snapshot),
      ).resolveElement(definition, (resolvedCatalog) => resolvedCatalog);
      final loading = const AsyncValue<RealmEditorCatalogState>.data(
        RealmEditorCatalogState.loading(),
      ).resolveElement(definition, (resolvedCatalog) => resolvedCatalog);

      expect(ready.requireValue.definitions, isNotEmpty);
      expect(loading, isA<AsyncLoading<TypeCatalog>>());
    });
  });

  group("Entry geometry and identity", () {
    test("calculates centers and squared distance", () {
      const first = EntryPlacement(x: 0, y: 0, width: 100, height: 100);
      const second = EntryPlacement(x: 100, y: 0, width: 100, height: 100);

      expect(first.center, const Offset(50, 50));
      expect(first.distanceSquaredTo(second), 10000);
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

final _rootType = ResolvedTypeRef(
  id: const QualifiedTypeId(namespace: "example", name: "Entry"),
  revision: 1,
);
