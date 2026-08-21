import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
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

  test("reports explicit offline state", () async {
    final states = <RealmConnectionState>[];
    final container = _containerWithRealm(
      _realm(status: ServiceStateStatus.offline),
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
    final id = recordId("service:test");
    final container = ProviderContainer(
      overrides: [
        realmIdProvider.overrideWithValue(id),
        selectedRealmProvider.overrideWith(
          (ref) => Future<Service?>.error(StateError("Unavailable")),
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

  test("expires an online heartbeat at its timeout", () async {
    final states = <RealmConnectionState>[];
    final container = _containerWithRealm(
      _realm(
        lastSeen: DateTime.now().subtract(
          const Duration(minutes: 1, seconds: 59, milliseconds: 850),
        ),
      ),
    );
    addTearDown(container.dispose);
    final subscription = container.listen(realmConnectionProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) states.add(next.requireValue);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await _waitForState(states, RealmConnectionState.online);
    await _waitForState(states, RealmConnectionState.offline);

    expect(
      states,
      containsAllInOrder([
        RealmConnectionState.checking,
        RealmConnectionState.online,
        RealmConnectionState.offline,
      ]),
    );
  });

  test("resumes when the selected realm returns online", () async {
    final states = <RealmConnectionState>[];
    final id = recordId("service:test");
    var selected = _realm(status: ServiceStateStatus.offline);
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

ProviderContainer _containerWithRealm(Service? realm) {
  final id = recordId("service:test");
  return ProviderContainer(
    overrides: [
      realmIdProvider.overrideWithValue(id),
      selectedRealmProvider.overrideWith((ref) async => realm),
    ],
  );
}

Service _realm({
  ServiceStateStatus status = ServiceStateStatus.online,
  DateTime? lastSeen,
}) => Service(
  serviceId: recordId("service:test"),
  revision: 1,
  name: "test_realm",
  role: CustomServiceRole(name: "realm", version: "1"),
  createdAt: DateTime.utc(2026),
  state: ServiceState(status: status, lastSeen: lastSeen ?? DateTime.now()),
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
