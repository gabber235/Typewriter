import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

Service service({
  String name = "test_service",
  ServiceRole? role,
  ServiceState? state,
}) => Service(
  serviceId: recordId("service:test"),
  revision: 1,
  name: name,
  role: role ?? HostServiceRole(version: "1"),
  createdAt: DateTime.utc(2025),
  state: state,
);

void main() {
  test("converts to and from Skir", () {
    final original = service(role: HostServiceRole(version: "1"));
    expect(Service.fromSkir(original.toSkir()), original);
  });

  test("detects host role", () {
    final value = service(role: HostServiceRole(version: "1"));
    expect(value.isHost, isTrue);
    expect(value.label, "Host");
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
    expect(value.lastSeen, isNull);
    expect(value.label, "Host");
  });
}
