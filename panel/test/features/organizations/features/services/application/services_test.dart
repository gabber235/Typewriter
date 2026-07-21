import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Service service({
  String name = "test_service",
  List<ServiceRole>? roles,
  ServiceState? state,
}) => Service(
  serviceId: recordId("service:test"),
  name: name,
  roles: roles ?? [RealmServiceRole(version: "1")],
  createdAt: DateTime.utc(2025),
  state: state,
);

void main() {
  test("converts to and from Skir", () {
    final original = service(roles: [RealmServiceRole(version: "1")]);
    expect(Service.fromSkir(original.toSkir()), original);
  });

  test("detects wrapped roles", () {
    final value = service(
      roles: [
        EngineServiceRole(version: "1"),
        RealmServiceRole(version: "1"),
      ],
    );
    expect(value.isEngine, isTrue);
    expect(value.isRealm, isTrue);
    expect(value.label, "Engine & Realm");
    expect(value.icon, Icons.dns);
  });

  test("explicit offline remains offline despite recent last seen", () {
    final value = service(
      state: ServiceState(
        status: ServiceStateStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 10)),
      ),
    );
    expect(value.isOnline, isFalse);
  });

  test("last seen older than two minutes is offline", () {
    final value = service(
      state: ServiceState(
        status: ServiceStateStatus.online,
        lastSeen: DateTime.now().subtract(
          const Duration(minutes: 2, seconds: 2),
        ),
      ),
    );
    expect(value.isOnline, isFalse);
  });

  test("formats display name and missing state", () {
    final value = service();
    expect(value.displayName, "Test Service");
    expect(value.lastSeenLabel, "Never");
    expect(value.label, "Realm");
  });
}
