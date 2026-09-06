import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("opens an active topology Realm from its route identifier", () async {
    final realm = _realm();
    final online = Completer<void>();
    final container =
        ProviderContainer.test(
          overrides: [
            routeParamProvider("realmId").overrideWithValue("test"),
            organizationTopologyStreamProvider.overrideWith(
              () => _FixtureTopology(realm),
            ),
          ],
        )..listen(realmConnectionProvider, (_, next) {
          if (next.value == RealmConnectionState.online &&
              !online.isCompleted) {
            online.complete();
          }
        });

    expect(await container.read(selectedRealmProvider.future), realm);
    await online.future.timeout(const Duration(seconds: 2));
    expect(container.read(realmInteractionProvider).suspended, isFalse);
  });

  test("reports no selection without a realm route", () async {
    final states = <RealmConnectionState>[];
    final container = ProviderContainer(
      overrides: [realmIdProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.notSelected);

    expect(states.last, RealmConnectionState.notSelected);
  });

  test("moves from checking to online", () async {
    final states = <RealmConnectionState>[];
    final container = _containerWithRealm(_realm());
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.online);

    expect(states, contains(RealmConnectionState.checking));
    expect(states.last, RealmConnectionState.online);
  });

  test("reports explicit inactive state", () async {
    final states = <RealmConnectionState>[];
    final container = _containerWithRealm(
      _realm(status: TopologyRuntimeStatus.failed),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.offline);

    expect(states.last, RealmConnectionState.offline);
  });

  test("reports unavailable for a missing realm", () async {
    final states = <RealmConnectionState>[];
    final container = _containerWithRealm(null);
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.unavailable);

    expect(states.last, RealmConnectionState.unavailable);
  });

  test("reports unavailable when realm resolution fails", () async {
    final states = <RealmConnectionState>[];
    final id = recordId("realm_instance:test");
    final container = ProviderContainer(
      overrides: [
        realmIdProvider.overrideWithValue(id),
        selectedRealmProvider.overrideWith(
          (ref) => Future<TopologyRealm?>.error(StateError("Unavailable")),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.unavailable);

    expect(states.last, RealmConnectionState.unavailable);
  });

  test("resumes when the selected Realm becomes active", () async {
    final states = <RealmConnectionState>[];
    final id = recordId("realm_instance:test");
    var selected = _realm(status: TopologyRuntimeStatus.failed);
    final container = ProviderContainer(
      overrides: [
        realmIdProvider.overrideWithValue(id),
        selectedRealmProvider.overrideWith((ref) async => selected),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.offline);
    states.clear();

    selected = _realm();
    container
      ..invalidate(selectedRealmProvider)
      ..invalidate(realmConnectionProvider);
    await _waitForState(states, RealmConnectionState.online);

    expect(states, contains(RealmConnectionState.checking));
    expect(states.last, RealmConnectionState.online);
  });
}

ProviderContainer _containerWithRealm(TopologyRealm? realm) {
  final id = recordId("realm_instance:test");
  return ProviderContainer(
    overrides: [
      realmIdProvider.overrideWithValue(id),
      selectedRealmProvider.overrideWith((ref) async => realm),
    ],
  );
}

TopologyRealm _realm({
  TopologyRuntimeStatus status = TopologyRuntimeStatus.active,
}) => TopologyRealm(
  realmId: recordId("realm_instance:test"),
  ownerHost: TopologyOwnerHost(
    id: recordId("service_host:host"),
    name: "test_realm",
  ),
  revision: 1,
  targetEngine: TopologyEngineTarget(
    engineId: "typewritermc:paper",
    versionConstraint: "*",
  ),
  state: TopologyRuntimeState(
    status: status,
    activeArtifactVersion: status == TopologyRuntimeStatus.active
        ? "1.0.0"
        : null,
    message: null,
    updatedAt: DateTime.now(),
  ),
);

Future<void> _waitForState(
  List<RealmConnectionState> states,
  RealmConnectionState expected,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (states.contains(expected)) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail("Did not observe $expected. States: $states");
}

class _FixtureTopology extends OrganizationTopologyStream {
  _FixtureTopology(this.realm);

  final TopologyRealm realm;

  @override
  Stream<OrganizationTopology> build() => Stream.value(
    OrganizationTopology(
      hosts: [],
      realmInstances: [realm],
      engineInstances: [],
    ),
  );
}
