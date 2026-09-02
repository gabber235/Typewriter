import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _publishSubject = "cloud.to.user.user1.organization.org1.services.watch";
const _listenSubject = "cloud.from.organization.org1.services.watch";
final _organizationId = recordId("organization:org1");

Service _service(String id, {String? name, int revision = 1}) => Service(
  serviceId: recordId("service:$id"),
  revision: revision,
  name: name ?? "Service $id",
  role: HostServiceRole(version: "1"),
  createdAt: DateTime.utc(2025),
);

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 2));
}

class _Harness {
  _Harness() {
    nats.registerHandler(
      _publishSubject,
      (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([]),
      ),
    );
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    subscription = container.listen(
      servicesProvider,
      (previous, next) => value = next,
      fireImmediately: true,
    );
  }

  final MockNatsClient nats = MockNatsClient();
  late final ProviderContainer container;
  late final ProviderSubscription<AsyncValue<List<Service>>> subscription;
  AsyncValue<List<Service>> value = const AsyncLoading();

  Future<void> start() => _waitFor(
    () =>
        nats.requests.isNotEmpty &&
        nats.subscriptionSubjects.contains(_listenSubject),
  );

  Future<List<Service>> emit(
    skir.WatchOrganizationServicesResponse response,
  ) async {
    final previous = value;
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.WatchOrganizationServicesResponse.serializer.toBytes(response),
    );
    await _waitFor(() => !identical(value, previous));
    return value.requireValue;
  }

  Future<List<Service>> emitWithoutChange(
    skir.WatchOrganizationServicesResponse response,
  ) async {
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.WatchOrganizationServicesResponse.serializer.toBytes(response),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container.read(servicesProvider).requireValue;
  }

  Future<Object> emitError(
    skir.WatchOrganizationServicesResponse response,
  ) async {
    final completer = Completer<Object>();
    final errorSubscription = container.listen(servicesProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !completer.isCompleted) {
        completer.complete(next.error!);
      }
    });
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.WatchOrganizationServicesResponse.serializer.toBytes(response),
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
          request.data,
        ),
        isA<skir.WatchOrganizationServicesRequest>(),
      );
    });

    test("reduces list, add, update, and remove", () async {
      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapList([
            _service("one").toSkir(),
          ]),
        ),
        [_service("one")],
      );
      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapAdd(
            _service("two").toSkir(),
          ),
        ),
        [_service("one"), _service("two")],
      );
      final updated = _service("one", name: "Updated", revision: 2);
      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapUpdate(updated.toSkir()),
        ),
        [updated, _service("two")],
      );
      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapRemove(
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
      final current = _service("one", name: "Current", revision: 3).copyWith(
        registration: ServiceRegistration(
          token: "sensitive-token",
          expiresAt: DateTime.utc(2027),
        ),
      );
      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapList([current.toSkir()]),
        ),
        [current],
      );

      expect(
        await harness.emitWithoutChange(
          skir.WatchOrganizationServicesResponse.wrapUpdate(
            _service("one", name: "Older", revision: 2).toSkir(),
          ),
        ),
        [current],
      );
      expect(
        await harness.emitWithoutChange(
          skir.WatchOrganizationServicesResponse.wrapUpdate(
            _service("one", name: "Divergent", revision: 3).toSkir(),
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
      final current = _service("one").copyWith(
        state: ServiceState(
          status: ServiceStateStatus.offline,
          lastSeen: DateTime.utc(2025, 1, 1),
        ),
      );
      final heartbeat = current.copyWith(
        state: ServiceState(
          status: ServiceStateStatus.online,
          lastSeen: DateTime.utc(2025, 1, 1, 0, 1),
        ),
      );
      await harness.emit(
        skir.WatchOrganizationServicesResponse.wrapList([current.toSkir()]),
      );

      expect(
        await harness.emit(
          skir.WatchOrganizationServicesResponse.wrapUpdate(heartbeat.toSkir()),
        ),
        [heartbeat],
      );
    });

    test("maps internal and unknown errors", () async {
      expect(
        await harness.emitError(
          skir.WatchOrganizationServicesResponse.createInternalError(),
        ),
        isA<ApiException>().having((error) => error.code, "code", 500),
      );
      harness.dispose();
      harness = _Harness();
      await harness.start();
      expect(
        await harness.emitError(skir.WatchOrganizationServicesResponse.unknown),
        isA<ApiException>().having((error) => error.code, "code", 422),
      );
    });
  });

  for (final auth in [
    (userId: null, organizationId: _organizationId),
    (userId: "user1", organizationId: null),
  ]) {
    test("null watch guard yields empty without publication", () async {
      final nats = MockNatsClient();
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => auth.userId),
          organizationIdProvider.overrideWith((ref) => auth.organizationId),
          natsProvider.overrideWithValue(nats),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(nats.dispose);
      final subscription = container.listen(
        servicesProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      expect(await container.read(servicesProvider.future), isEmpty);
      expect(nats.publications, isEmpty);
      expect(nats.requests, isEmpty);
      expect(nats.subscriptionSubjects, isEmpty);
    });
  }
}
