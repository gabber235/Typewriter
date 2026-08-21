import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _bindSubject = "cloud.to.user.user1.organization.org1.services.bind";
const _updateSubject = "cloud.to.user.user1.organization.org1.services.update";
const _unbindSubject = "cloud.to.user.user1.organization.org1.services.unbind";
final _organizationId = recordId("organization:org1");

Service _service({String name = "Original", int revision = 1}) => Service(
  serviceId: recordId("service:service1"),
  revision: revision,
  name: name,
  role: HostServiceRole(version: "1"),
  createdAt: DateTime.utc(2025),
);

class _SeededServices extends Services {
  _SeededServices(this.services);
  final List<Service> services;

  @override
  Stream<List<Service>> build() async* {
    yield services;
  }

  void observe(Service service) {
    state = AsyncData([service]);
  }
}

class _Harness {
  _Harness({String? userId = "user1", Object? organizationId = _default}) {
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => userId),
        organizationIdProvider.overrideWith(
          (ref) => organizationId == _default
              ? _organizationId
              : organizationId as skir.RecordId?,
        ),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        servicesProvider.overrideWith(
          () => notifier = _SeededServices([_service()]),
        ),
      ],
    );
  }

  static const _default = Object();
  final MockNatsClient nats = MockNatsClient();
  late final _SeededServices notifier;
  late final ProviderContainer container;
  ProviderSubscription<AsyncValue<List<Service>>>? subscription;

  Future<void> ready() async {
    subscription = container.listen(servicesProvider, (previous, next) {});
    await container.read(servicesProvider.future);
  }

  void respond(String subject, Uint8List Function(Uint8List data) handler) =>
      nats.registerHandler(subject, handler);

  void dispose() {
    subscription?.close();
    container.dispose();
    nats.dispose();
  }
}

Matcher _apiException(int code) =>
    isA<ApiException>().having((error) => error.code, "code", code);

void main() {
  group("service mutations", () {
    late _Harness harness;

    setUp(() async {
      harness = _Harness();
      await harness.ready();
    });

    tearDown(() => harness.dispose());

    test("bind sends exact subject and decoded token on success", () async {
      skir.BindServiceRequest? request;
      harness.respond(_bindSubject, (data) {
        request = skir.BindServiceRequest.serializer.fromBytes(data);
        return skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createSuccess(
            serviceId: "service1",
            serviceName: "Service",
            serviceRole: skir.ServiceRole.createHost(version: "1"),
          ),
        );
      });

      await harness.container
          .read(servicesProvider.notifier)
          .bindService("registration token");

      expect(harness.nats.requests.single.subject, _bindSubject);
      expect(request!.registrationToken, "registration token");
    });

    test("bind maps invalid token", () async {
      harness.respond(
        _bindSubject,
        (data) => skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createInvalidRegistrationTokenError(),
        ),
      );

      await expectLater(
        harness.container
            .read(servicesProvider.notifier)
            .bindService("invalid"),
        throwsA(_apiException(400)),
      );
    });

    test(
      "update sends complete state and applies the canonical response",
      () async {
        final updated = _service(name: "Updated");
        final canonical = updated.copyWith(revision: updated.revision + 1);
        skir.UpdateOrganizationServiceRequest? request;
        harness.respond(_updateSubject, (data) {
          request = skir.UpdateOrganizationServiceRequest.serializer.fromBytes(
            data,
          );
          return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
            skir.UpdateOrganizationServiceResponse.wrapSuccess(
              canonical.toSkir(),
            ),
          );
        });

        final result = await harness.container
            .read(servicesProvider.notifier)
            .updateService(updated);

        expect(harness.nats.requests.single.subject, _updateSubject);
        expect(request!.serviceId, updated.serviceId);
        expect(request!.expectedRevision, updated.revision);
        expect(request!.name, "Updated");
        expect(result, isA<MutationSuccess>());
        expect(harness.container.read(servicesProvider).requireValue, [
          canonical,
        ]);
      },
    );

    test(
      "delayed update response cannot replace a newer observation",
      () async {
        final newest = _service(name: "Newest", revision: 4);
        final delayed = _service(name: "Delayed", revision: 2);
        harness.respond(_updateSubject, (data) {
          harness.notifier.observe(newest);
          return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
            skir.UpdateOrganizationServiceResponse.wrapSuccess(
              delayed.toSkir(),
            ),
          );
        });

        final result = await harness.container
            .read(servicesProvider.notifier)
            .updateService(_service(name: "Requested"));

        expect(result, isA<MutationSuccess>());
        expect((result as MutationSuccess).revision, newest.revision);
        expect(harness.container.read(servicesProvider).requireValue, [newest]);
      },
    );

    test(
      "update returns unavailable and rolls back service not found",
      () async {
        harness.respond(
          _updateSubject,
          (data) => skir.UpdateOrganizationServiceResponse.serializer.toBytes(
            skir.UpdateOrganizationServiceResponse.createServiceNotFoundError(),
          ),
        );

        final result = await harness.container
            .read(servicesProvider.notifier)
            .updateService(_service(name: "Updated"));

        expect(result, isA<MutationUnavailable>());
        expect(harness.container.read(servicesProvider).requireValue, [
          _service(),
        ]);
      },
    );

    test(
      "unbind sends decoded string id and keeps optimistic removal",
      () async {
        skir.UnbindServiceRequest? request;
        harness.respond(_unbindSubject, (data) {
          request = skir.UnbindServiceRequest.serializer.fromBytes(data);
          return skir.UnbindServiceResponse.serializer.toBytes(
            skir.UnbindServiceResponse.createSuccess(),
          );
        });

        await harness.container
            .read(servicesProvider.notifier)
            .deleteService(_service().serviceId);

        expect(harness.nats.requests.single.subject, _unbindSubject);
        expect(request!.serviceId, "service1");
        expect(harness.container.read(servicesProvider).requireValue, isEmpty);
      },
    );

    test("unbind rolls back typed service not found response", () async {
      harness.respond(
        _unbindSubject,
        (data) => skir.UnbindServiceResponse.serializer.toBytes(
          skir.UnbindServiceResponse.createServiceNotFoundError(),
        ),
      );

      await expectLater(
        harness.container
            .read(servicesProvider.notifier)
            .deleteService(_service().serviceId),
        throwsA(_apiException(404)),
      );
      expect(harness.container.read(servicesProvider).requireValue, [
        _service(),
      ]);
    });
  });

  for (final mutation in ["bind", "update", "unbind"]) {
    for (final guard in ["auth", "organization"]) {
      test("$mutation checks $guard before request", () async {
        final harness = _Harness(
          userId: guard == "auth" ? null : "user1",
          organizationId: guard == "organization" ? null : _organizationId,
        );
        addTearDown(harness.dispose);
        await harness.ready();
        final notifier = harness.container.read(servicesProvider.notifier);

        final operation = switch (mutation) {
          "bind" => notifier.bindService("token"),
          "update" => notifier.updateService(_service(name: "Updated")),
          _ => notifier.deleteService(_service().serviceId),
        };

        await expectLater(operation, throwsA(isA<ApiException>()));
        expect(harness.nats.requests, isEmpty);
      });
    }
  }
}
