import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("production source returns typed unavailable results", () async {
    const source = UnavailableRealmEditorCatalogSource();
    final route = RealmEditorCatalogRoute(
      organizationId: recordId("organization:test"),
      realmId: recordId("service:test"),
    );

    final fetch = await source.fetch(route, RealmEditorCatalogRequest());
    final watch = await source.watchInvalidations(route).single;

    expect(fetch, isA<RealmEditorCatalogFetchUnavailable>());
    expect(watch, isA<RealmEditorCatalogWatchUnavailable>());
  });

  test("routes isolate fetch and invalidation subjects", () {
    final route = RealmEditorCatalogRoute(
      organizationId: recordId("organization:alpha"),
      realmId: recordId("service:beta"),
    );

    expect(
      route.fetchSubject,
      "service.to.beta.organization.alpha.realm.editor.catalog.fetch",
    );
    expect(
      route.invalidationRequestSubject,
      "service.to.beta.organization.alpha.realm.editor.catalog.invalidate",
    );
    expect(
      route.invalidationSubject,
      "service.from.beta.organization.alpha.realm.editor.catalog.invalidate",
    );
  });

  test("request stays loading through connection and catalog fetch", () async {
    final connection = Completer<RealmConnectionState>();
    final fetch = Completer<RealmEditorCatalogFetchResult>();
    final source = _ControlledSource((_) => fetch.future);
    addTearDown(source.close);
    final container = ProviderContainer.test(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith((ref) => connection.future),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    final provider = realmCatalogProvider(
      RealmEditorCatalogRequest(
        types: {ResolvedTypeRef(id: DeclaredTypeId(_elementId), revision: 1)},
      ),
    );
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    expect(
      container.read(provider),
      isA<AsyncLoading<RealmEditorCatalogSnapshot>>(),
    );
    connection.complete(RealmConnectionState.online);
    await _waitFor(() => source.fetchCount > 0);
    expect(
      container.read(provider),
      isA<AsyncLoading<RealmEditorCatalogSnapshot>>(),
    );

    final snapshot = _elementSnapshot("Ready", "1");
    fetch.complete(RealmEditorCatalogFetched(snapshot));
    expect(await container.read(provider.future), snapshot);
  });

  test(
    "actual fetch failure surfaces an error and later invalidation recovers",
    () async {
      final source = _ControlledSource(
        (_) async => RealmEditorCatalogFetchUnavailable([
          realmEditorCatalogUnavailableDiagnostic("Catalog fetch failed"),
        ]),
      );
      addTearDown(source.close);
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(
            recordId("organization:test"),
          ),
          realmIdProvider.overrideWithValue(recordId("service:test")),
          realmConnectionProvider.overrideWith(
            (ref) async => RealmConnectionState.online,
          ),
          realmEditorCatalogSourceProvider.overrideWithValue(source),
        ],
      );
      final provider = realmCatalogProvider(const RealmEditorCatalogRequest());
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);

      await _waitFor(() => container.read(provider).hasError);
      expect(
        container.read(provider).error,
        isA<RealmCatalogUnavailableException>(),
      );
      final snapshot = _elementSnapshot("Recovered", "2");
      source
        ..result = ((_) async => RealmEditorCatalogFetched(snapshot))
        ..invalidate(const CatalogGeneration("2"));
      await _waitFor(
        () => container.read(provider).value?.generation.value == "2",
      );
      expect(container.read(provider).requireValue, snapshot);
    },
  );

  test(
    "refresh retains prior data but blocks current catalog commands",
    () async {
      final first = _elementSnapshot("First", "1");
      final refresh = Completer<RealmEditorCatalogFetchResult>();
      final source = _ControlledSource(
        (_) async => RealmEditorCatalogFetched(first),
      );
      addTearDown(source.close);
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(
            recordId("organization:test"),
          ),
          realmIdProvider.overrideWithValue(recordId("service:test")),
          realmConnectionProvider.overrideWith(
            (ref) async => RealmConnectionState.online,
          ),
          realmEditorCatalogSourceProvider.overrideWithValue(source),
        ],
      );
      final provider = realmCatalogProvider(const RealmEditorCatalogRequest());
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      final fullSubscription = container.listen(
        realmEditorCatalogProvider,
        (_, _) {},
      );
      addTearDown(fullSubscription.close);
      expect(await container.read(provider.future), first);

      source
        ..result = ((_) => refresh.future)
        ..invalidate(const CatalogGeneration("2"));
      await _waitFor(() => container.read(provider).isLoading);
      expect(container.read(provider).value, first);
      expect(container.read(provider).currentCatalog, isNull);
      expect(container.read(realmEditorCatalogProvider).currentCatalog, isNull);

      final second = _elementSnapshot("Second", "2");
      refresh.complete(RealmEditorCatalogFetched(second));
      await _waitFor(() => container.read(provider).currentCatalog == second);
      await _waitFor(
        () =>
            container.read(realmEditorCatalogProvider).currentCatalog == second,
      );
    },
  );

  test("eligible discovered elements become available definitions", () async {
    final source = _ElementSource();
    addTearDown(source.close);
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Future.value(RealmConnectionState.online),
        ),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      realmEditorCatalogProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    final definitionsSubscription = container.listen(
      availableElementDefinitionsFutureProvider,
      (previous, next) {},
    );
    addTearDown(definitionsSubscription.close);

    await _waitFor(
      () =>
          container
              .read(availableElementDefinitionsFutureProvider)
              .value
              ?.isNotEmpty ==
          true,
    );
    final definition = container
        .read(availableElementDefinitionsFutureProvider)
        .requireValue
        .single;

    expect(definition.typeId.uuid, _elementId);
    expect(definition.name, "Synthetic Entry");
    expect(definition.description, "Verifies Typewriter discovery");
    expect(
      definition.icon,
      const IconValue.iconify("material-symbols:science"),
    );
    expect(definition.color, const Color(0xFF7C4DFF));
  });

  test("asynchronous element definitions follow catalog updates", () async {
    var snapshot = _elementSnapshot("First", "1");
    final container = ProviderContainer(
      overrides: [
        realmEditorCatalogProvider.overrideWith((ref) async => snapshot),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      availableElementDefinitionsFutureProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    expect(
      container.read(availableElementDefinitionsFutureProvider),
      isA<AsyncLoading<List<ElementDefinition>>>(),
    );

    await _waitFor(
      () =>
          container
              .read(availableElementDefinitionsFutureProvider)
              .value
              ?.single
              .name ==
          "First",
    );

    snapshot = _elementSnapshot("Second", "2");
    container.invalidate(realmEditorCatalogProvider);
    await _waitFor(
      () =>
          container
              .read(availableElementDefinitionsFutureProvider)
              .value
              ?.single
              .name ==
          "Second",
    );
  });

  test("provider disposes the realm watch on disconnect", () async {
    final source = _TrackingSource();
    final connection = Completer<void>();
    var online = true;
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith((ref) async {
          await connection.future;
          return online
              ? RealmConnectionState.online
              : RealmConnectionState.offline;
        }),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      realmEditorCatalogProvider,
      (previous, next) {},
    );

    addTearDown(subscription.close);

    expect(container.read(realmEditorCatalogProvider).isLoading, isTrue);
    connection.complete();
    await _waitFor(() => source.watchCount == 1);
    online = false;
    container.invalidate(realmConnectionProvider);
    await _waitFor(() => source.cancelCount == 1);

    expect(source.fetchCount, 1);
  });

  test("provider disposes the realm watch with its container", () async {
    final source = _TrackingSource();
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Future.value(RealmConnectionState.online),
        ),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    final subscription = container.listen(
      realmEditorCatalogProvider,
      (previous, next) {},
    );
    await _waitFor(() => source.watchCount == 1);

    subscription.close();
    container.dispose();
    await _waitFor(() => source.cancelCount == 1);
  });

  test("provider replaces the realm watch after navigation", () async {
    final source = _TrackingSource();
    var realmId = recordId("service:first");
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWith((ref) => realmId),
        realmConnectionProvider.overrideWith(
          (ref) => Future.value(RealmConnectionState.online),
        ),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      realmEditorCatalogProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    await _waitFor(() => source.watchCount == 1);

    realmId = recordId("service:second");
    container.invalidate(realmIdProvider);
    await _waitFor(() => source.watchCount == 2 && source.cancelCount == 1);

    expect(source.routes.map((route) => route.realmId), [
      recordId("service:first"),
      recordId("service:second"),
    ]);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail("Condition was not reached");
}

final class _TrackingSource implements RealmEditorCatalogSource {
  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  }) => Future.error(UnsupportedError("Initialization is outside this test"));

  int fetchCount = 0;
  int watchCount = 0;
  int cancelCount = 0;
  final List<RealmEditorCatalogRoute> routes = [];

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async {
    fetchCount++;
    return RealmEditorCatalogFetched(
      RealmEditorCatalogSnapshot(
        catalog: TypeCatalog([]),
        generation: const CatalogGeneration("1"),
      ),
    );
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) {
    watchCount++;
    routes.add(route);
    final controller = StreamController<RealmEditorCatalogWatchEvent>(
      onCancel: () {
        cancelCount++;
      },
    );
    return controller.stream;
  }
}

final class _ControlledSource implements RealmEditorCatalogSource {
  _ControlledSource(this.result);

  Future<RealmEditorCatalogFetchResult> Function(RealmEditorCatalogRequest)
  result;
  final _events = StreamController<RealmEditorCatalogWatchEvent>();
  int fetchCount = 0;

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) {
    fetchCount++;
    return result(request);
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => _events.stream;

  void invalidate(CatalogGeneration generation) =>
      _events.add(RealmEditorCatalogInvalidated(generation));

  Future<void> close() => _events.close();

  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  }) => Future.error(UnsupportedError("Initialization is outside this test"));
}

const _elementId = "019d1c2a8f7b7cc18c2a4a7b2fd1e281";

RealmEditorCatalogSnapshot _elementSnapshot(String name, String generation) {
  final type = ResolvedTypeRef(id: DeclaredTypeId(_elementId), revision: 1);
  return RealmEditorCatalogSnapshot(
    catalog: const TypeCatalog([]),
    generation: CatalogGeneration(generation),
    elements: {
      _elementId: RealmElementCatalogEntry(
        originArtifactId: "typewritermc:conformance",
        sourcePart: "common",
        definition: DiscoveredElementDefinition(
          id: _elementId,
          type: type,
          name: name,
          description: "Verifies Typewriter discovery",
          icon: const IconValue.iconify("material-symbols:science"),
          color: const Color(0xFF7C4DFF),
          availability: ElementAvailability.always(),
        ),
        presentationSubject: _catalogSubject(type),
        eligible: true,
        available: true,
      ),
    },
  );
}

TypedCatalogPresentationSubject _catalogSubject(ResolvedTypeRef type) => (
  target: type,
  descriptor: TypedValueEnvelope(rootType: type, rootValue: RecordValue({})),
);

final class _ElementSource implements RealmEditorCatalogSource {
  @override
  Future<RealmTypedValueInitializationResult> initialize(
    RealmEditorCatalogRoute route, {
    required CatalogGeneration generation,
    required ResolvedTypeRef root,
    required DataValue? supplied,
    required TypeRegistry registry,
  }) => Future.error(UnsupportedError("Initialization is outside this test"));

  final _watch = StreamController<RealmEditorCatalogWatchEvent>();

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async {
    return RealmEditorCatalogFetched(_elementSnapshot("Synthetic Entry", "1"));
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => _watch.stream;

  Future<void> close() => _watch.close();
}
