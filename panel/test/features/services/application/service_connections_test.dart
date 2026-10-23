import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("keeps a host reachable while its heartbeat is updated", (
    tester,
  ) async {
    final organization = skir.recordId("organization:heartbeat");
    final now = DateTime.now();
    final service = skir.Service(
      serviceId: skir.recordId("service:heartbeat"),
      revision: 1,
      name: "heartbeat",
      role: skir.ServiceRole.createHost(version: "1"),
      createdAt: now,
      state: skir.ServiceState(
        status: skir.ServiceStatus.online,
        lastSeen: now,
      ),
      organization: null,
      registration: null,
    );
    final host = skir.ServiceHost(
      hostId: skir.recordId("service_host:heartbeat"),
      serviceId: service.serviceId,
      revision: 1,
      entrypoint: "PAPER",
      canHostRealm: true,
      supportedEngines: [],
      topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
      state: skir.HostRuntimeState(
        status: skir.HostRuntimeStatus.active,
        message: null,
        updatedAt: now,
      ),
    );
    final source = StreamController<List<skir.Service>>(sync: true);
    addTearDown(source.close);
    final states = <bool>[];
    final container =
        ProviderContainer.test(
          overrides: [
            organizationIdProvider.overrideWithValue(organization),
            canonicalOrganizationServicesProvider(organization)
                .overrideWith(() => _Services(source.stream)),
            organizationTopologyProvider.overrideWith(
              (ref) async => skir.OrganizationTopologySnapshot(
                hosts: [host],
                realms: [],
                engines: [],
              ),
            ),
          ],
        )..listen(
          hostConnectedProvider(host.hostId),
          (_, next) => states.add(next),
        );
    source.add([service]);
    await tester.pump();
    await tester.pump();
    expect(container.read(hostConnectedProvider(host.hostId)), isTrue);
    states.clear();

    source.add([
      (service.toMutable()
            ..state =
                (service.state!.toMutable()
                      ..lastSeen = now.add(const Duration(seconds: 30)))
                    .toFrozen())
          .toFrozen(),
    ]);
    await tester.pump();
    expect(states, isNot(contains(false)));
    expect(container.read(hostConnectedProvider(host.hostId)), isTrue);

    container.dispose();
    await tester.pump();
  });

  testWidgets(
    "expires at the deadline without a new event and refreshes on resume",
    (tester) async {
      var now = DateTime.utc(2026, 9, 6);
      await withClock(Clock(() => now), () async {
        final service = skir.Service(
          serviceId: skir.recordId("service:deadline"),
          revision: 1,
          name: "deadline",
          role: skir.ServiceRole.createHost(version: "1"),
          createdAt: now,
          state: skir.ServiceState(
            status: skir.ServiceStatus.online,
            lastSeen: now,
          ),
          organization: null,
          registration: null,
        );

        final host = skir.ServiceHost(
          hostId: skir.recordId("service_host:deadline"),
          serviceId: service.serviceId,
          revision: 1,
          entrypoint: "PAPER",
          canHostRealm: true,
          supportedEngines: [],
          topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
          state: skir.HostRuntimeState(
            status: skir.HostRuntimeStatus.active,
            message: null,
            updatedAt: now,
          ),
        );

        final container = ProviderContainer.test(
          overrides: [
            canonicalServicesProvider.overrideWith((ref) async => [service]),
            organizationTopologyProvider.overrideWith(
              (ref) async => skir.OrganizationTopologySnapshot(
                hosts: [host],
                realms: [],
                engines: [],
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

class _Services extends CanonicalOrganizationServices {
  _Services(this.values);
  final Stream<List<skir.Service>> values;

  @override
  Stream<List<skir.Service>> build(skir.RecordId organizationId) => values;
}
