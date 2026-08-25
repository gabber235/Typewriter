import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("subtype provider exposes all returned concrete descendants", () async {
    final direct = _type("DirectTrigger");
    final indirect = _type("IndirectTrigger");
    final abstract = _type("AbstractTrigger");
    final unrelated = _type("Unrelated");
    final source = _SubtypeSource(
      matches: [direct, abstract, indirect],
      abstractMatches: {abstract},
      concreteRoots: {_type("SequenceEntry")},
    );
    final container = _container(source);
    addTearDown(container.dispose);

    final subscription = container.listen(
      pageElementTypesProvider(_kind),
      (previous, next) {},
    );
    addTearDown(subscription.close);
    await _waitFor(() => subscription.read().value is PageElementTypesReady);

    final state = subscription.read().requireValue;
    expect(state, isA<PageElementTypesReady>());
    final types = (state as PageElementTypesReady).types;
    expect(types, containsAll([_type("SequenceEntry"), direct, indirect]));
    expect(types, isNot(contains(abstract)));
    expect(types, isNot(contains(unrelated)));
    expect(source.requestedTarget, _type("SequenceEntry"));
  });

  test("loading and unavailable subtype results reject safely", () async {
    final loadingSource = _SubtypeSource(holdFetch: true);
    final loadingContainer = _container(loadingSource);
    addTearDown(loadingContainer.dispose);
    final loading = loadingContainer.listen(
      pageElementTypesProvider(_kind),
      (previous, next) {},
    );
    addTearDown(loading.close);

    expect(loading.read(), isA<AsyncLoading<PageElementTypesState>>());

    final unavailableContainer = _container(_SubtypeSource(unavailable: true));
    addTearDown(unavailableContainer.dispose);
    final unavailable = unavailableContainer.listen(
      pageElementTypesProvider(_kind),
      (previous, next) {},
    );
    addTearDown(unavailable.close);
    await _waitFor(
      () => unavailable.read().value is PageElementTypesUnavailable,
    );

    expect(unavailable.read().requireValue, isA<PageElementTypesUnavailable>());
  });
}

const _kind = PageKindRef(id: "test-page", revision: 1);

ProviderContainer _container(RealmEditorCatalogSource source) =>
    ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Stream.value(RealmConnectionState.online),
        ),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );

ResolvedTypeRef _type(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "typewriter/v1", name: name),
  revision: 1,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail("Condition was not reached");
}

final class _SubtypeSource implements RealmEditorCatalogSource {
  _SubtypeSource({
    this.matches = const [],
    this.abstractMatches = const {},
    this.concreteRoots = const {},
    this.unavailable = false,
    this.holdFetch = false,
  });

  final List<ResolvedTypeRef> matches;
  final Set<ResolvedTypeRef> abstractMatches;
  final Set<ResolvedTypeRef> concreteRoots;
  final bool unavailable;
  final bool holdFetch;
  ResolvedTypeRef? requestedTarget;
  final _watch = StreamController<RealmEditorCatalogWatchEvent>();

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async {
    if (holdFetch) return Completer<RealmEditorCatalogFetchResult>().future;
    if (unavailable) {
      return RealmEditorCatalogFetchResult.unavailable([
        realmEditorCatalogUnavailableDiagnostic("Unavailable"),
      ]);
    }
    final subtypeResults = <String, RealmEditorSubtypeResult>{};
    for (final query in request.subtypeQueries) {
      requestedTarget = query.target;
      subtypeResults[query.id] = RealmEditorSubtypeResult(
        queryId: query.id,
        matches: matches,
      );
    }
    return RealmEditorCatalogFetchResult.fetched(
      RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([
          for (final type in concreteRoots)
            TypeDefinition(id: type, kind: NominalTypeKind.concrete),
          for (final type in matches)
            TypeDefinition(
              id: type,
              kind: abstractMatches.contains(type)
                  ? NominalTypeKind.openAbstract
                  : NominalTypeKind.concrete,
            ),
        ]),
        generation: const CatalogGeneration("1"),
        subtypeResults: subtypeResults,
        pageCatalog: RealmPageCatalog(
          definitions: {
            _kind: RealmPageDefinition(
              kind: _kind,
              name: "Test",
              description: null,
              icon: IconValue.iconify("mdi:test-tube"),
              color: Color(0xFF000000),
              editor: RealmGraphPageEditor(
                direction: GraphDirection.leftToRight,
                nodeTypes: [_type("SequenceEntry")],
              ),
              originArtifactId: "test",
              sourcePart: "test",
            ),
          },
        ),
      ),
    );
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => _watch.stream;
}
