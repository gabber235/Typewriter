import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("a typed relation field selects concrete compatible children", () {
    final snapshot = RealmEditorCatalogSnapshot(
      catalog: TypeCatalog([
        TypeDefinition(id: _page, kind: NominalTypeKind.concrete,
          representation: RecordType(fields: {
            "elements": TypeField(name: "elements", type: ListType(
              element: ReferenceType(target: _element),
            )),
          })),
        TypeDefinition(id: _element, kind: NominalTypeKind.openAbstract),
        TypeDefinition(id: _entry, kind: NominalTypeKind.concrete, parents: [_element]),
        TypeDefinition(id: _other, kind: NominalTypeKind.concrete),
      ]),
      generation: const CatalogGeneration("test"),
      resourceDefinitions: {
        CoreResourceDefinitionIds.element: RealmResourceDefinition(
          id: CoreResourceDefinitionIds.element,
          acceptedRoot: NamedType(_element),
        ),
      },
      relations: {
        "page.elements": RealmRelationDefinition(
          id: "page.elements",
          source: _page,
          target: _element,
          onSourceDelete: RealmRelationDeletePolicy.cascade,
          onTargetDelete: RealmRelationDeletePolicy.clear,
          sourceEndpoint: RealmRelationEndpointDefinition(
            owner: _page,
            path: DataPath.root.field("elements"),
            side: RealmRelationEndpointSide.source,
            cardinality: RealmRelationCardinality.many,
          ),
          targetEndpoint: null,
          families: const {"resource.ownership"},
        ),
      },
    );

    final field = snapshot.relationField(_page, DataPath.root.field("elements"));
    expect(field, isNotNull);
    expect(snapshot.creatableTargets(field!), [_entry]);
    expect(field.accepts(_other, TypeRegistry(snapshot.catalog)), isFalse);
  });
}

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name), revision: 1,
);
final _page = _type("Page");
final _element = _type("Element");
final _entry = _type("Entry");
final _other = _type("Other");
