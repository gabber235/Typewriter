import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("page scope exposes only compatible element definitions", () {
    final policy = ValueNotifier<AsyncValue<PageEntryCreationPolicy>>(
      AsyncData(_policy),
    );
    addTearDown(policy.dispose);
    final scope = pageElementTypeScope(policy: policy);

    expect(
      scope.evaluate(_result(_compatibleDefinition), SearchQueryContext.empty),
      isA<SearchResultVisible>(),
    );
    expect(
      scope.evaluate(
        _result(_incompatibleDefinition),
        SearchQueryContext.empty,
      ),
      isA<SearchResultHidden>(),
    );
    expect(
      scope.evaluate(_unrelatedResult, SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
  });

  test("page scope hides definitions while policy is unavailable", () {
    final policy = ValueNotifier<AsyncValue<PageEntryCreationPolicy>>(
      const AsyncLoading(),
    );
    addTearDown(policy.dispose);
    final scope = pageElementTypeScope(policy: policy);

    expect(
      scope.evaluate(_result(_compatibleDefinition), SearchQueryContext.empty),
      isA<SearchResultHidden>(),
    );
  });

  test("fixed page command follows live compatibility", () {
    final policy = ValueNotifier<AsyncValue<PageEntryCreationPolicy>>(
      AsyncData(_policy),
    );
    addTearDown(policy.dispose);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final command = container.read(
      Provider(
        (ref) => createElementOnPageCommand(
          ref: ref,
          organizationId: recordId("organization:test"),
          realmId: recordId("realm:test"),
          pageId: recordId("page:test"),
          policy: policy,
        ),
      ),
    );

    expect(
      command.evaluate(_target(_compatibleDefinition)),
      isA<SearchCommandEnabled>(),
    );
    expect(
      command.evaluate(_target(_incompatibleDefinition)),
      isA<SearchCommandHidden>(),
    );

    policy.value = const AsyncLoading();

    expect(
      command.evaluate(_target(_compatibleDefinition)),
      isA<SearchCommandDisabled>(),
    );
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
final _policy = PageEntryCreationPolicy(
  placement: PageEntryCreationPlacement.graph,
  types: {_compatibleType},
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

SearchCommandTarget _target(ElementDefinition definition) {
  final result = _result(definition);
  return SearchCommandTarget(
    primary: result,
    selection: [result],
    query: SearchQueryContext.empty,
  );
}
