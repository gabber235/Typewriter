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

  test("eligible discovered elements become available definitions", () async {
    final source = _ElementSource();
    addTearDown(source.close);
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith(
          (ref) => Stream.value(RealmConnectionState.online),
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
      availableElementDefinitionsProvider,
      (previous, next) {},
    );
    addTearDown(definitionsSubscription.close);

    await _waitFor(
      () => container.read(availableElementDefinitionsProvider).isNotEmpty,
    );
    final definition = container
        .read(availableElementDefinitionsProvider)
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

  test("provider disposes the realm watch on disconnect", () async {
    final source = _TrackingSource();
    final connection = StreamController<RealmConnectionState>();
    addTearDown(connection.close);
    final container = ProviderContainer(
      overrides: [
        organizationIdProvider.overrideWithValue(recordId("organization:test")),
        realmIdProvider.overrideWithValue(recordId("service:test")),
        realmConnectionProvider.overrideWith((ref) => connection.stream),
        realmEditorCatalogSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      realmEditorCatalogProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    connection.add(RealmConnectionState.online);
    await _waitFor(() => source.watchCount == 1);
    connection.add(RealmConnectionState.offline);
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
          (ref) => Stream.value(RealmConnectionState.online),
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
          (ref) => Stream.value(RealmConnectionState.online),
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

const _elementId = "019d1c2a8f7b7cc18c2a4a7b2fd1e281";

final class _ElementSource implements RealmEditorCatalogSource {
  final _watch = StreamController<RealmEditorCatalogWatchEvent>();

  @override
  Future<RealmEditorCatalogFetchResult> fetch(
    RealmEditorCatalogRoute route,
    RealmEditorCatalogRequest request, {
    CatalogGeneration? expectedGeneration,
  }) async {
    final type = ResolvedTypeRef(id: DeclaredTypeId(_elementId), revision: 1);
    return RealmEditorCatalogFetched(
      RealmEditorCatalogSnapshot(
        catalog: const TypeCatalog([]),
        generation: const CatalogGeneration("1"),
        elements: {
          _elementId: RealmElementCatalogEntry(
            originArtifactId: "typewritermc:conformance",
            sourcePart: "common",
            definition: DiscoveredElementDefinition(
              id: _elementId,
              type: type,
              name: "Synthetic Entry",
              description: "Verifies Typewriter discovery",
              icon: const IconValue.iconify("material-symbols:science"),
              color: const Color(0xFF7C4DFF),
              availability: ElementAvailability.always(),
            ),
            eligible: true,
            available: true,
          ),
        },
      ),
    );
  }

  @override
  Stream<RealmEditorCatalogWatchEvent> watchInvalidations(
    RealmEditorCatalogRoute route,
  ) => _watch.stream;

  Future<void> close() => _watch.close();
}
