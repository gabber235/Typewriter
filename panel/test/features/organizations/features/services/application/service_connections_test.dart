import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets(
    "expires at the deadline without a new event and refreshes on resume",
    (tester) async {
      var now = DateTime.utc(2026, 9, 6);
      await withClock(Clock(() => now), () async {
        final service = Service(
          serviceId: skir.recordId("service:deadline"),
          revision: 1,
          name: "deadline",
          role: HostServiceRole(version: "1"),
          createdAt: now,
          state: ServiceState(status: ServiceStateStatus.online, lastSeen: now),
        );

        final host = TopologyHost(
          hostId: skir.recordId("service_host:deadline"),
          serviceId: service.serviceId,
          revision: 1,
          entrypoint: "PAPER",
          canHostRealm: true,
          supportedEngines: [],
          topologyRevision: const TopologyRevision(desired: 1, applied: 1),
          state: TopologyHostState(
            status: TopologyHostStatus.active,
            message: null,
            updatedAt: now,
          ),
        );

        final container = ProviderContainer.test(
          overrides: [
            canonicalServicesProvider.overrideWith((ref) async => [service]),
            organizationTopologyProvider.overrideWith(
              (ref) async => OrganizationTopology(
                hosts: [host],
                realmInstances: [],
                engineInstances: [],
              ),
            ),
          ],
        );
        final provider = serviceConnectionsProvider;
        final subscription = container.listen(provider, (_, next) {});
        final connection = hostConnectedProvider(host.hostId);
        final hostSubscription = container.listen(connection, (_, next) {});

        for (
          var attempt = 0;
          attempt < 10 && !container.read(connection);
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 1));
        }

        expect(container.read(connection), isTrue);
        expect(container.read(provider)[service.serviceId], isTrue);
        now = now.add(const Duration(minutes: 2));
        await tester.pump(const Duration(minutes: 2));
        expect(container.read(provider)[service.serviceId], isFalse);
        expect(container.read(connection), isFalse);

        now = service.state!.lastSeen;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(container.read(provider)[service.serviceId], isTrue);
        expect(container.read(connection), isTrue);

        hostSubscription.close();
        subscription.close();
        container.dispose();
        await tester.pump();
      });
    },
  );
}
