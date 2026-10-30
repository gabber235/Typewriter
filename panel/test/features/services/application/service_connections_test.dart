import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _host = paperHost("paper");

void main() {
  testWidgets("a heartbeat keeps the host connected without a gap", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [
          service(
            "paper",
            role: skir.ServiceRole.createHost(version: "1"),
            lastSeen: clock.now(),
          ),
        ],
        topology: skir.OrganizationTopologySnapshot(
          hosts: [_host],
          realms: [],
          engines: [],
        ),
      ),
    ]);
    final states = <bool>[];
    panel.container.listen(
      hostConnectedProvider(_host.hostId),
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    expect(states, [true]);

    panel.world.nats.announceServices(
      acme.organizationId,
      skir.OrganizationServicesChanged.wrapUpdate(
        service(
          "paper",
          role: skir.ServiceRole.createHost(version: "1"),
          lastSeen: clock.now().add(const Duration(seconds: 30)),
        ),
      ),
    );
    await panel.settle();

    expect(states, everyElement(isTrue));
    expect(panel.services.statusOf("Paper host", "Paper"), "Active");
  });

  testWidgets("a host without a heartbeat goes offline at its deadline and "
      "is checked again when the panel resumes", (tester) async {
    var now = DateTime.utc(2026, 9, 6);
    await withClock(Clock(() => now), () async {
      final lastSeen = now;
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              role: skir.ServiceRole.createHost(version: "1"),
              lastSeen: lastSeen,
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      expect(panel.services.statusOf("Paper host", "Paper"), "Active");

      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));
      await panel.settle();
      expect(panel.services.statusOf("Paper host", "Paper"), "Offline");

      now = lastSeen;
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await panel.settle();
      expect(panel.services.statusOf("Paper host", "Paper"), "Active");
    });
  });
}
