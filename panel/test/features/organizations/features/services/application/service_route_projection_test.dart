import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final _organization = skir.recordId("organization:route");

void main() {
  _routeProjectionTests<List<Service>>(
    name: "services",
    provider: canonicalServicesProvider,
    result: canonicalServicesProvider.future,
    sourceOverride: (values) =>
        canonicalOrganizationServicesProvider(_organization)
            .overrideWith(() => _Services(values)),
    first: const [],
    second: [
      Service(
        serviceId: skir.recordId("service:one"),
        revision: 1,
        name: "One",
        role: HostServiceRole(version: "1"),
        createdAt: DateTime.utc(2026),
      ),
    ],
  );
  _routeProjectionTests<OrganizationTopology>(
    name: "topology",
    provider: organizationTopologyProvider,
    result: organizationTopologyProvider.future,
    sourceOverride: (values) =>
        organizationTopologyControllerProvider(_organization)
            .overrideWith(() => _Topology(values)),
    first: OrganizationTopology.empty,
    second: OrganizationTopology(
      hosts: [
        TopologyHost(
          hostId: skir.recordId("service_host:one"),
          serviceId: skir.recordId("service:one"),
          revision: 1,
          entrypoint: "PAPER",
          canHostRealm: true,
          supportedEngines: [],
          topologyRevision: const TopologyRevision(desired: 1, applied: 1),
          state: TopologyHostState(
            status: TopologyHostStatus.active,
            message: null,
            updatedAt: DateTime.utc(2026),
          ),
        ),
      ],
      realmInstances: [],
      engineInstances: [],
    ),
  );
}

void _routeProjectionTests<T>({
  required String name,
  required ProviderListenable<AsyncValue<T>> provider,
  required ProviderListenable<Future<T>> result,
  required Override Function(Stream<T>) sourceOverride,
  required T first,
  required T second,
}) {
  group("$name route projection", () {
    test("disposes safely before the canonical stream emits", () async {
      final started = Completer<void>();
      final cancelled = Completer<void>();
      final source = StreamController<T>(
        onListen: started.complete,
        onCancel: cancelled.complete,
      );
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(_organization),
          sourceOverride(source.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.close();
      });
      final subscription = container.listen(provider, (_, next) {});
      await started.future.timeout(const Duration(seconds: 2));
      expect(container.read(provider).isLoading, isTrue);

      subscription.close();
      await container.pump();
      await cancelled.future.timeout(const Duration(seconds: 2));
      await pumpEventQueue();
    });

    test("follows canonical values through the watched future", () async {
      final source = StreamController<T>(sync: true);
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(_organization),
          sourceOverride(source.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.close();
      });
      final subscription = container.listen(provider, (_, next) {});
      addTearDown(subscription.close);

      source.add(first);
      expect(await container.read(result), first);
      source.add(second);
      expect(await container.read(result), second);
    });

    test("forwards terminal canonical errors", () async {
      final source = StreamController<T>(sync: true);
      final reported = Completer<Object>();
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          organizationIdProvider.overrideWithValue(_organization),
          sourceOverride(source.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.close();
      });
      final subscription = container.listen(provider, (_, next) {
        if (next.hasError && !reported.isCompleted) {
          reported.complete(next.error!);
        }
      });
      addTearDown(subscription.close);
      source.add(first);
      await container.read(result);

      final error = ApiException.unknownResponseMessage();
      source.addError(error, StackTrace.current);
      await container.pump();
      expect(
        await reported.future.timeout(const Duration(seconds: 2)),
        same(error),
      );
    });

    test("follows recovery owned by the canonical provider", () async {
      final listening = Completer<void>();
      var attempts = 0;
      final source = StreamController<T>.broadcast(
        sync: true,
        onListen: () {
          if (++attempts == 2) listening.complete();
        },
      );
      final container = ProviderContainer.test(
        retry: (count, _) => count == 0 ? Duration.zero : null,
        overrides: [
          organizationIdProvider.overrideWithValue(_organization),
          sourceOverride(source.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await source.close();
      });
      final subscription = container.listen(provider, (_, next) {});
      addTearDown(subscription.close);
      source.add(first);
      expect(await container.read(result), first);

      source.addError(
        ApiException.unknownResponseMessage(),
        StackTrace.current,
      );
      await listening.future.timeout(const Duration(seconds: 2));
      source.add(second);
      expect(await container.read(result), second);
      expect(attempts, 2);
    });
  });
}

class _Services extends CanonicalOrganizationServices {
  _Services(this.values);
  final Stream<List<Service>> values;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) => values;
}

class _Topology extends OrganizationTopologyController {
  _Topology(this.values);
  final Stream<OrganizationTopology> values;

  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) => values;
}
