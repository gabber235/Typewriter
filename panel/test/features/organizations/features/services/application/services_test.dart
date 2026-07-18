import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/services/application/services.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

Service service({
  String name = "test_service",
  List<skir.ServiceRole> roles = const [],
  skir.ServiceState? state,
}) => Service(
  serviceId: recordId("service:test"),
  name: name,
  roles: roles,
  createdAt: DateTime.utc(2025),
  state: state,
);

void main() {
  test("converts to and from Skir", () {
    final original = service(
      roles: [skir.ServiceRole.createRealm(version: "1")],
    );
    expect(Service.fromSkir(original.toSkir()), original);
  });

  test("detects wrapped roles", () {
    final value = service(
      roles: [
        skir.ServiceRole.createEngine(version: "1"),
        skir.ServiceRole.createRealm(version: "1"),
      ],
    );
    expect(value.isEngine, isTrue);
    expect(value.isRealm, isTrue);
    expect(value.typeLabel, "Engine & Realm");
    expect(value.icon, Icons.dns);
  });

  test("explicit offline remains offline despite recent last seen", () {
    final value = service(
      state: skir.ServiceState(
        status: skir.ServiceStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 10)),
      ),
    );
    expect(value.isOnline, isFalse);
  });

  test("unknown state with recent last seen is online", () {
    final value = service(
      state: skir.ServiceState(
        status: skir.ServiceStatus.unknown,
        lastSeen: DateTime.now().subtract(const Duration(seconds: 10)),
      ),
    );
    expect(value.isOnline, isTrue);
  });

  test("last seen older than two minutes is offline", () {
    final value = service(
      state: skir.ServiceState(
        status: skir.ServiceStatus.online,
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
    expect(value.typeLabel, "Unknown");
  });
}
