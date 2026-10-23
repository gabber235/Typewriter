import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _publishSubject = "cloud.to.user.user1.organization.org1.services.watch";
const _listenSubject = "cloud.from.organization.org1.services.watch";
final _organizationId = skir.recordId("organization:org1");

skir.Service _service(String id, {String? name, int revision = 1}) =>
    skir.Service(
      serviceId: skir.recordId("service:$id"),
      revision: revision,
      name: name ?? "Service $id",
      role: skir.ServiceRole.createHost(version: "1"),
      createdAt: DateTime.utc(2025),
      organization: null,
      registration: null,
      state: null,
    );

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 2));
}

class _Harness {
  _Harness({skir.WatchOrganizationServicesResponse? initialReply}) {
    nats.registerHandler(
      _publishSubject,
      (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
        initialReply ?? skir.WatchOrganizationServicesResponse.wrapList([]),
      ),
    );
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWith(() => FakeNats(nats)),
      ],
    );
    subscription = container.listen(
      canonicalServicesProvider,
      (previous, next) => value = next,
      fireImmediately: true,
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;
  late final ProviderSubscription<AsyncValue<List<skir.Service>>> subscription;
  AsyncValue<List<skir.Service>> value = const AsyncLoading();

  Future<void> start() => _waitFor(
    () =>
        nats.requests.isNotEmpty &&
        nats.subscriptionSubjects.contains(_listenSubject),
  );

  Future<List<skir.Service>> emit(
    skir.OrganizationServicesChanged event,
  ) async {
    final previous = value;
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.OrganizationServicesChanged.serializer.toBytes(event),
    );
    await _waitFor(() => !identical(value, previous));
    return await container.read(canonicalServicesProvider.future);
  }

  Future<List<skir.Service>> emitWithoutChange(
    skir.OrganizationServicesChanged event,
  ) async {
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.OrganizationServicesChanged.serializer.toBytes(event),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container.read(canonicalServicesProvider).requireValue;
  }

  Future<Object> emitError(skir.OrganizationServicesChanged event) async {
    final completer = Completer<Object>();
    final errorSubscription = container.listen(
      canonicalOrganizationServicesProvider(_organizationId),
      (previous, next) {
        if (next.hasError && !completer.isCompleted) {
          completer.complete(next.error!);
        }
      },
    );
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.OrganizationServicesChanged.serializer.toBytes(event),
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 2));
    } finally {
      errorSubscription.close();
    }
  }

  void dispose() {
    subscription.close();
    container.dispose();
    nats.dispose();
  }
}

void main() {
  group("services watch", () {
    late _Harness harness;

    setUp(() async {
      harness = _Harness();
      await harness.start();
    });

    tearDown(() => harness.dispose());

    test("requests initial data and subscribes to exact subject", () {
      final request = harness.nats.requests.single;
      expect(request.subject, _publishSubject);
      expect(harness.nats.subscriptionSubjects, contains(_listenSubject));
      expect(
        skir.WatchOrganizationServicesRequest.serializer.fromBytes(
          request.payload,
        ),
        isA<skir.WatchOrganizationServicesRequest>(),
      );
    });

    test("reduces replacement, update, and remove", () async {
      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapReplace([_service("one")]),
        ),
        [_service("one")],
      );
      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapReplace([
            _service("one"),
            _service("two"),
          ]),
        ),
        [_service("one"), _service("two")],
      );
      final updated = _service("one", name: "Updated", revision: 2);
      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapUpdate(updated),
        ),
        [updated, _service("two")],
      );
      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapRemove(
            _service("two").serviceId,
          ),
        ),
        [updated],
      );
    });

    test("ignores older and divergent equal revision watch updates", () async {
      final errors = <FlutterErrorDetails>[];
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final current =
          (_service("one", name: "Current", revision: 3).toMutable()
                ..registration = skir.ServiceRegistration(
                  token: "sensitive-token",
                  expiresAt: DateTime.utc(2027),
                ))
              .toFrozen();
      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapReplace([current]),
        ),
        [current],
      );

      expect(
        await harness.emitWithoutChange(
          skir.OrganizationServicesChanged.wrapUpdate(
            _service("one", name: "Older", revision: 2),
          ),
        ),
        [current],
      );
      expect(
        await harness.emitWithoutChange(
          skir.OrganizationServicesChanged.wrapUpdate(
            _service("one", name: "Divergent", revision: 3),
          ),
        ),
        [current],
      );
      expect(errors, hasLength(1));
      expect(errors.single.exceptionAsString(), contains("Service one"));
      expect(errors.single.exceptionAsString(), contains("revision 3"));
      expect(
        errors.single.exceptionAsString(),
        isNot(contains("sensitive-token")),
      );
    });

    test("accepts equal revision heartbeat state updates", () async {
      final current =
          (_service("one").toMutable()
                ..state = skir.ServiceState(
                  status: skir.ServiceStatus.offline,
                  lastSeen: DateTime.utc(2025, 1, 1),
                ))
              .toFrozen();
      final heartbeat =
          (current.toMutable()
                ..state = skir.ServiceState(
                  status: skir.ServiceStatus.online,
                  lastSeen: DateTime.utc(2025, 1, 1, 0, 1),
                ))
              .toFrozen();
      await harness.emit(
        skir.OrganizationServicesChanged.wrapReplace([current]),
      );

      expect(
        await harness.emit(
          skir.OrganizationServicesChanged.wrapUpdate(heartbeat),
        ),
        [heartbeat],
      );
    });

    test("maps unknown event errors", () async {
      expect(
        await harness.emitError(skir.OrganizationServicesChanged.unknown),
        isA<ApiException>().having((error) => error.code, "code", 422),
      );
    });
  });

  test("delayed reconnect snapshot preserves confirmed facts and replacement membership", () async {
    final harness = _Harness(
      initialReply: skir.WatchOrganizationServicesResponse.wrapList([
        _service("one"),
        _service("removed"),
      ]),
    );
    addTearDown(harness.dispose);
    await harness.start();
    await _waitFor(() => harness.value.value?.length == 2);
    final reply = Completer<Uint8List>();
    harness.nats.registerHandler(_publishSubject, (_) => reply.future);
    harness.nats
      ..setConnectionState(const NatsConnecting())
      ..setConnectionState(const NatsConnected());
    await _waitFor(() => harness.nats.requests.length == 2);
    final renamed = _service("one", name: "Confirmed rename", revision: 3);
    harness.container.read(serviceResourceRepositoryProvider(_organizationId))
      ..acceptService(renamed)
      ..acceptService(_service("removed", revision: 9));
    await _waitFor(() => harness.value.value?.first.revision == 3);
    reply.complete(
      skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([_service("one")]),
      ),
    );
    await _waitFor(() => harness.value.value?.length == 1);
    expect(harness.value.requireValue, [renamed]);
    expect(
      await harness.emit(
        skir.OrganizationServicesChanged.wrapUpdate(
          _service("one", name: "Later event", revision: 4),
        ),
      ),
      [_service("one", name: "Later event", revision: 4)],
    );
    expect(
      await harness.emit(
        skir.OrganizationServicesChanged.wrapReplace([
          _service("removed", revision: 1),
        ]),
      ),
      [_service("removed", revision: 1)],
    );
  });

  test("confirmed fact before initial snapshot enters the same reconciliation owner", () async {
    final reply = Completer<Uint8List>();
    final harness = _Harness();
    harness.nats.registerHandler(_publishSubject, (_) => reply.future);
    addTearDown(harness.dispose);
    await harness.start();
    final renamed = _service("one", name: "Confirmed first", revision: 2);
    harness.container
        .read(serviceResourceRepositoryProvider(_organizationId))
        .acceptService(renamed);
    await _waitFor(() => harness.value.value?.single.revision == 2);
    reply.complete(
      skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([_service("one")]),
      ),
    );
    await pumpEventQueue();
    expect(harness.value.requireValue, [renamed]);
  });

  for (final auth in [
    (userId: null, organizationId: _organizationId),
    (userId: "user1", organizationId: null),
  ]) {
    test("null watch guard yields empty without publication", () async {
      final nats = FakeNatsClient();
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => auth.userId),
          organizationIdProvider.overrideWith((ref) => auth.organizationId),
          natsProvider.overrideWith(() => FakeNats(nats)),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(nats.dispose);
      final subscription = container.listen(
        canonicalServicesProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      expect(await container.read(canonicalServicesProvider.future), isEmpty);
      expect(nats.requests, isEmpty);
      expect(nats.subscriptionSubjects, isEmpty);
    });
  }
}
