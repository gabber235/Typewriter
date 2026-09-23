import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("creation option identity includes concrete type arguments", () {
    final first = AuthoringCreationOption(
      definition: CoreResourceDefinitionIds.book,
      root: _book.copyWith(arguments: const [StringType()]),
      label: "Book",
    );
    final second = AuthoringCreationOption(
      definition: CoreResourceDefinitionIds.book,
      root: _book.copyWith(arguments: const [BooleanType()]),
      label: "Book",
    );
    expect(first.id, isNot(second.id));
  });

  test("standalone search excludes a resource with an ownership parent", () async {
    final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
      AsyncData(RealmEditorCatalogState.ready(RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([
          TypeDefinition(id: _book, kind: NominalTypeKind.concrete),
          TypeDefinition(id: _entry, kind: NominalTypeKind.concrete),
        ]),
        generation: const CatalogGeneration("1"),
        resourceDefinitions: {
          CoreResourceDefinitionIds.book: RealmResourceDefinition(
            id: CoreResourceDefinitionIds.book,
            acceptedRoot: NamedType(_book),
          ),
          CoreResourceDefinitionIds.element: RealmResourceDefinition(
            id: CoreResourceDefinitionIds.element,
            acceptedRoot: NamedType(_entry),
          ),
        },
        relations: {
          "book.entries": RealmRelationDefinition(
            id: "book.entries",
            source: _book,
            target: _entry,
            onSourceDelete: RealmRelationDeletePolicy.cascade,
            onTargetDelete: RealmRelationDeletePolicy.clear,
            sourceEndpoint: null,
            targetEndpoint: null,
            families: const {"resource.ownership"},
          ),
        },
      ))),
    );
    addTearDown(catalog.dispose);
    final controller = SourceController(
      source: AuthoringCreationSearchSource(catalog),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    final section = controller.snapshot.nodes.single as SearchSectionNode;
    final result = (section.children.single as SearchResultNode).result;
    final option = result.payload as AuthoringCreationOption;
    expect(option.definition, CoreResourceDefinitionIds.book);
    expect(option.root, _book);

    controller.updateQuery("missing");
    await pumpEventQueue();
    expect(controller.snapshot.nodes, isEmpty);
  });

  test("relation search offers the concrete type accepted by its field", () async {
    final snapshot = RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(
          id: _book,
          kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {
            "entries": TypeField(
              name: "entries",
              type: ListType(element: ReferenceType(target: _entry)),
            ),
          }),
        ),
        TypeDefinition(id: _entry, kind: NominalTypeKind.concrete),
      ]),
      generation: const CatalogGeneration("1"),
      resourceDefinitions: {
        CoreResourceDefinitionIds.element: RealmResourceDefinition(
          id: CoreResourceDefinitionIds.element,
          acceptedRoot: NamedType(_entry),
        ),
      },
      relations: {
        "book.entries": RealmRelationDefinition(
          id: "book.entries",
          source: _book,
          target: _entry,
          onSourceDelete: RealmRelationDeletePolicy.cascade,
          onTargetDelete: RealmRelationDeletePolicy.clear,
          sourceEndpoint: RealmRelationEndpointDefinition(
            owner: _book,
            path: DataPath.root.field("entries"),
            side: RealmRelationEndpointSide.source,
            cardinality: RealmRelationCardinality.many,
          ),
          targetEndpoint: null,
          families: const {"resource.ownership"},
        ),
      },
    );
    final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
      AsyncData(RealmEditorCatalogState.ready(snapshot)),
    );
    final field = ValueNotifier<AsyncValue<RealmRelationField>>(
      AsyncData(snapshot.relationField(_book, DataPath.root.field("entries"))!),
    );
    addTearDown(catalog.dispose);
    addTearDown(field.dispose);
    final controller = SourceController(
      source: AuthoringCreationSearchSource(catalog, field: field),
      baseSelectors: const [],
    );
    addTearDown(controller.dispose);
    await pumpEventQueue();

    final section = controller.snapshot.nodes.single as SearchSectionNode;
    final option =
        (section.children.single as SearchResultNode).result.payload
            as AuthoringCreationOption;
    expect(option.root, _entry);
  });
}

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name), revision: 1,
);
final _book = _type("Book");
final _entry = _type("Entry");
