import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("default policy maps every page layout to revision one", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final policy = container.read(pageElementTypePolicyProvider);

    expect(policy.acceptedType(PageType.sequence), _type("TriggerEntry"));
    expect(policy.acceptedType(PageType.static), _type("StaticEntry"));
    expect(policy.acceptedType(PageType.scene), _type("CinematicEntry"));
    expect(policy.acceptedType(PageType.manifest), _type("ManifestEntry"));
  });

  test("subtype provider exposes all returned concrete descendants", () async {
    final direct = _type("DirectTrigger");
    final indirect = _type("IndirectTrigger");
    final abstract = _type("AbstractTrigger");
    final unrelated = _type("Unrelated");
    final source = _SubtypeSource(
      matches: [direct, abstract, indirect],
      abstractMatches: {abstract},
    );
    final container = _container(source);
    addTearDown(container.dispose);

    final subscription = container.listen(
      pageElementTypesProvider(PageType.sequence),
      (previous, next) {},
    );
    addTearDown(subscription.close);
    await _waitFor(() => subscription.read().value is PageElementTypesReady);

    final state = subscription.read().requireValue;
    expect(state, isA<PageElementTypesReady>());
    final types = (state as PageElementTypesReady).types;
    expect(types, containsAll([direct, indirect]));
    expect(types, isNot(contains(abstract)));
    expect(types, isNot(contains(unrelated)));
    expect(source.requestedTarget, _type("TriggerEntry"));
  });

  test("loading and unavailable subtype results reject safely", () async {
    final loadingSource = _SubtypeSource(holdFetch: true);
    final loadingContainer = _container(loadingSource);
    addTearDown(loadingContainer.dispose);
    final loading = loadingContainer.listen(
      pageElementTypesProvider(PageType.sequence),
      (previous, next) {},
    );
    addTearDown(loading.close);

    expect(loading.read(), isA<AsyncLoading<PageElementTypesState>>());

    final unavailableContainer = _container(_SubtypeSource(unavailable: true));
    addTearDown(unavailableContainer.dispose);
    final unavailable = unavailableContainer.listen(
      pageElementTypesProvider(PageType.sequence),
      (previous, next) {},
    );
    addTearDown(unavailable.close);
    await _waitFor(
      () => unavailable.read().value is PageElementTypesUnavailable,
    );

    expect(unavailable.read().requireValue, isA<PageElementTypesUnavailable>());
  });
}

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
    this.unavailable = false,
    this.holdFetch = false,
  });

  final List<ResolvedTypeRef> matches;
  final Set<ResolvedTypeRef> abstractMatches;
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
      ),
    );
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => _watch.stream;
}
