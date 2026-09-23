import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("page field scope accepts only compatible element definitions", () {
    final field = ValueNotifier<AsyncValue<RealmRelationField>>(AsyncData(_field));
    final catalog = ValueNotifier<AsyncValue<RealmEditorCatalogState>>(
      AsyncData(RealmEditorCatalogState.ready(RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([
          TypeDefinition(id: _compatibleType, kind: NominalTypeKind.concrete),
          TypeDefinition(id: _incompatibleType, kind: NominalTypeKind.concrete),
        ]),
        generation: const CatalogGeneration("test"),
      ))),
    );
    addTearDown(field.dispose);
    addTearDown(catalog.dispose);
    final scope = pageRelationFieldScope(field: field, catalog: catalog);

    expect(scope.evaluate(_result(_compatibleDefinition), SearchQueryContext.empty), isA<SearchResultVisible>());
    expect(scope.evaluate(_result(_incompatibleDefinition), SearchQueryContext.empty), isA<SearchResultHidden>());
    expect(scope.evaluate(_unrelatedResult, SearchQueryContext.empty), isA<SearchResultHidden>());

    field.value = const AsyncLoading();
    expect(scope.evaluate(_result(_compatibleDefinition), SearchQueryContext.empty), isA<SearchResultHidden>());
  });
}

final _compatibleType = ResolvedTypeRef(
  id: DeclaredTypeId("0123456789abcdef0123456789abcdef"),
  revision: 1,
);
final _incompatibleType = ResolvedTypeRef(
  id: DeclaredTypeId("fedcba9876543210fedcba9876543210"),
  revision: 1,
);
final _pageType = ResolvedTypeRef(
  id: const QualifiedTypeId(namespace: "test", name: "Page"), revision: 1,
);
final _field = RealmRelationField(
  relation: RealmRelationDefinition(
    id: "page.elements",
    source: _pageType,
    target: _compatibleType,
    onSourceDelete: RealmRelationDeletePolicy.cascade,
    onTargetDelete: RealmRelationDeletePolicy.clear,
    sourceEndpoint: null,
    targetEndpoint: null,
    families: const {"resource.ownership"},
  ),
  endpoint: RealmRelationEndpointDefinition(
    owner: _pageType,
    path: DataPath.root.field("elements"),
    side: RealmRelationEndpointSide.source,
    cardinality: RealmRelationCardinality.many,
  ),
  target: _compatibleType,
);
final _compatibleDefinition = _definition("Compatible", _compatibleType);
final _incompatibleDefinition = _definition("Incompatible", _incompatibleType);

ElementDefinition _definition(String name, ResolvedTypeRef type) =>
    ElementDefinition(
      rootType: type,
      name: name,
      description: "$name element",
      color: Colors.blue,
      icon: const IconValue.iconify("fa-solid:star"),
    );

SearchResult _result(ElementDefinition definition) => SearchResult(
  id: "element_type:${definition.typeId.uuid}",
  type: elementTypeSearchResultType,
  payload: definition,
  title: definition.name,
);

final _unrelatedResult = SearchResult(
  id: "unrelated",
  type: const SearchResultType(
    id: "unrelated",
    rowRendererId: "unrelated",
    label: "Unrelated",
  ),
  payload: Object(),
);
