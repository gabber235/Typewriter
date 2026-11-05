import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _watchSubject = "cloud.to.user.ada.organization.acme.services.watch";
final _organization = acme.organizationId;
final _services = canonicalOrganizationServicesProvider(_organization);

void main() {
  test("watch events replace, update and remove services", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);
    await world.initialized();
    world.container.listen(_services, (_, _) {});
    final services = world.servicesOf(_organization);

    await world.container.read(_services.future);

    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapReplace([
          service("one", status: null),
        ]),
        (services) => services.length == 1,
      ),
      [service("one", status: null)],
    );
    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapReplace([
          service("one", status: null),
          service("two", status: null),
        ]),
        (services) => services.length == 2,
      ),
      [service("one", status: null), service("two", status: null)],
    );
    final updated = service("one", status: null, name: "Updated", revision: 2);
    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapUpdate(updated),
        (services) => services.first.revision == 2,
      ),
      [updated, service("two", status: null)],
    );
    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapRemove(
          service("two", status: null).serviceId,
        ),
        (services) => services.length == 1,
      ),
      [updated],
    );
  });

  test("older and divergent equal revision updates are ignored and "
      "reported without the registration token", () async {
    final errors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final current =
        (service("one", status: null, name: "Current", revision: 3).toMutable()
              ..registration = skir.ServiceRegistration(
                token: "sensitive-token",
                expiresAt: DateTime.utc(2027),
              ))
            .toFrozen();
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(services: [current]),
    ]);
    await world.initialized();
    world.container.listen(_services, (_, _) {});
    final services = world.servicesOf(_organization);

    expect(await world.container.read(_services.future), [current]);

    for (final ignored in [
      service("one", status: null, name: "Older", revision: 2),
      service("one", status: null, name: "Divergent", revision: 3),
    ]) {
      world.nats.announceServices(
        _organization,
        skir.OrganizationServicesChanged.wrapUpdate(ignored),
      );
    }
    final marker = service("marker", status: null);
    await services.announce(
      skir.OrganizationServicesChanged.wrapUpdate(marker),
      (services) => services.length == 2,
    );

    expect(world.container.read(_services).requireValue, [current, marker]);
    expect(errors, hasLength(1));
    final report = errors.single.exceptionAsString();
    expect(report, contains("Service one"));
    expect(report, contains("revision 3"));
    expect(report, isNot(contains("sensitive-token")));
  });

  test("an equal revision heartbeat updates the service state", () async {
    final current =
        (service("one", status: null).toMutable()
              ..state = skir.ServiceState(
                status: skir.ServiceStatus.offline,
                lastSeen: DateTime.utc(2025),
              ))
            .toFrozen();
    final heartbeat =
        (current.toMutable()
              ..state = skir.ServiceState(
                status: skir.ServiceStatus.online,
                lastSeen: DateTime.utc(2025, 1, 1, 0, 1),
              ))
            .toFrozen();
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(services: [current]),
    ]);
    await world.initialized();
    world.container.listen(_services, (_, _) {});
    final services = world.servicesOf(_organization);

    await world.container.read(_services.future);

    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapUpdate(heartbeat),
        (services) => services.single.state == heartbeat.state,
      ),
      [heartbeat],
    );
  });

  test("an unknown watch event fails the projection with an unknown "
      "response error", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);
    await world.initialized();
    world.container.listen(_services, (_, _) {});
    await world.container.read(_services.future);

    world.nats.announceServices(
      _organization,
      skir.OrganizationServicesChanged.unknown,
    );

    final failed = await world.container.eventually(
      _services,
      (value) => value.hasError,
      description: "the failed projection",
    );
    expect(
      failed.error,
      isA<ApiException>().having((error) => error.code, "code", 422),
    );
  });

  test("a snapshot delayed past a reconnect keeps confirmed renames and "
      "takes the incoming membership", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [
          service("one", status: null),
          service("removed", status: null),
        ],
      ),
    ]);
    await world.initialized();
    world.container.listen(_services, (_, _) {});
    final services = world.servicesOf(_organization);

    expect(await world.container.read(_services.future), hasLength(2));
    final reply = Completer<Uint8List>();
    world.nats.registerHandler(_watchSubject, (_) => reply.future);

    world.nats
      ..disconnect()
      ..reconnect();
    await eventually(
      () => expect(world.nats.requestsTo(_watchSubject), hasLength(2)),
    );
    final renamed = service(
      "one",
      status: null,
      name: "Confirmed rename",
      revision: 3,
    );
    world.container.read(serviceResourceRepositoryProvider(_organization))
      ..acceptService(renamed)
      ..acceptService(service("removed", status: null, revision: 9));
    await world.container.eventually(
      _services,
      (value) => value.value?.first.revision == 3,
      description: "the confirmed rename",
    );
    reply.complete(
      skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([
          service("one", status: null),
        ]),
      ),
    );

    expect(
      (await world.container.eventually(
        _services,
        (value) => value.value?.length == 1,
        description: "the delayed snapshot",
      )).requireValue,
      [renamed],
    );
    final later = service(
      "one",
      status: null,
      name: "Later event",
      revision: 4,
    );
    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapUpdate(later),
        (services) => services.single.revision == 4,
      ),
      [later],
    );
    expect(
      await services.announce(
        skir.OrganizationServicesChanged.wrapReplace([
          service("removed", status: null, revision: 1),
        ]),
        (services) =>
            services.single.serviceId ==
            service("removed", status: null).serviceId,
      ),
      [service("removed", status: null, revision: 1)],
    );
  });

  test("a rename confirmed before the first snapshot survives that "
      "snapshot", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(),
    ]);
    await world.initialized();
    final reply = Completer<Uint8List>();
    world.nats.registerHandler(_watchSubject, (_) => reply.future);
    world.container.listen(_services, (_, _) {});
    await eventually(() {
      expect(world.nats.connected, isTrue);
      expect(world.nats.connection.requests, isNotEmpty);
    });
    final renamed = service(
      "one",
      status: null,
      name: "Confirmed first",
      revision: 2,
    );

    world.container
        .read(serviceResourceRepositoryProvider(_organization))
        .acceptService(renamed);
    await world.container.eventually(
      _services,
      (value) => value.value?.singleOrNull?.revision == 2,
      description: "the confirmed rename",
    );
    reply.complete(
      skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([
          service("one", status: null),
        ]),
      ),
    );
    await pumpEventQueue();

    expect(world.container.read(_services).requireValue, [renamed]);
  });

  test("signed out, the services are empty and nothing is requested", () async {
    final world = testWorld([
      servicesBackend(services: [service("one", status: null)]),
    ]);
    world.container.listen(_services, (_, _) {});

    expect(await world.container.read(_services.future), isEmpty);
    expect(world.nats.connected, isFalse);
  });

  test("without an organization in the route, the services are empty and "
      "nothing is requested", () async {
    final world = testWorld([
      signedIn(ada, organization: acme),
      servicesBackend(services: [service("one", status: null)]),
    ]);
    world.container.listen(canonicalServicesProvider, (_, _) {});

    expect(
      await world.container.read(canonicalServicesProvider.future),
      isEmpty,
    );
    expect(world.nats.connected, isFalse);
  });
}
