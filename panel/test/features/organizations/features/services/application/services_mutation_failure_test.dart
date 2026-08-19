import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _updateSubject = "cloud.to.user.user1.organization.org1.services.update";
const _unbindSubject = "cloud.to.user.user1.organization.org1.services.unbind";
final _organizationId = recordId("organization:org1");

Service _service({String name = "Original", int revision = 1}) => Service(
  serviceId: recordId("service:service1"),
  revision: revision,
  name: name,
  roles: [RealmServiceRole(version: "1")],
  createdAt: DateTime.utc(2025),
);

class _SeededServices extends Services {
  @override
  Stream<List<Service>> build() => Stream.value([_service()]);

  void observe(Service service) {
    state = AsyncData([service]);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWithValue(_organizationId),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        servicesProvider.overrideWith(() => notifier = _SeededServices()),
      ],
    );
  }

  final MockNatsClient nats = MockNatsClient();
  late final _SeededServices notifier;
  late final ProviderContainer container;
  ProviderSubscription<AsyncValue<List<Service>>>? subscription;

  Future<void> ready() async {
    subscription = container.listen(servicesProvider, (previous, next) {});
    await container.read(servicesProvider.future);
  }

  void respond(String subject, Uint8List Function(Uint8List data) handler) {
    nats.registerHandler(subject, handler);
  }

  void dispose() {
    subscription?.close();
    container.dispose();
    nats.dispose();
  }
}

void main() {
  late _Harness harness;
  late FlutterExceptionHandler? previousErrorHandler;
  late List<FlutterErrorDetails> reports;

  setUp(() async {
    reports = [];
    previousErrorHandler = FlutterError.onError;
    FlutterError.onError = reports.add;
    harness = _Harness();
    await harness.ready();
  });

  tearDown(() {
    FlutterError.onError = previousErrorHandler;
    harness.dispose();
  });

  test("update preserves exact validation diagnostics", () async {
    harness.respond(
      _updateSubject,
      (data) => skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.wrapValidationError(
          skir.ServiceUpdateValidationError.nameInvalid,
        ),
      ),
    );

    final result = await harness.container
        .read(servicesProvider.notifier)
        .updateService(_service(name: "Updated"));

    expect(result, isA<MutationInvalid>());
    expect(
      (result as MutationInvalid).diagnostics.single.message,
      "The service contains invalid values",
    );
    expect(reports, isEmpty);
  });

  test("update preserves conflict details without reporting", () async {
    final actual = _service(name: "Canonical", revision: 3);
    harness.respond(
      _updateSubject,
      (data) => skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.createConflictError(
          expectedRevision: 1,
          actual: actual.toSkir(),
        ),
      ),
    );

    final result = await harness.container
        .read(servicesProvider.notifier)
        .updateService(_service(name: "Updated"));

    expect(result, isA<MutationConflict>());
    final conflict = result as MutationConflict;
    expect(conflict.expectedRevision, 1);
    expect(conflict.actualRevision, 3);
    expect(harness.container.read(servicesProvider).requireValue, [actual]);
    expect(reports, isEmpty);
  });

  test(
    "unexpected update preserves a newer observation and reports once",
    () async {
      final newest = _service(name: "Newest", revision: 4);
      harness.respond(_updateSubject, (data) {
        harness.notifier.observe(newest);
        throw StateError("transport failed");
      });

      final result = await harness.container
          .read(servicesProvider.notifier)
          .updateService(_service(name: "Requested"));

      expect(result, isA<MutationUnavailable>());
      expect(
        (result as MutationUnavailable).diagnostics.single.message,
        "The service update could not be completed",
      );
      expect(harness.container.read(servicesProvider).requireValue, [newest]);
      expect(reports, hasLength(1));
      expect(reports.single.context.toString(), "while updating a service");
    },
  );

  test("unexpected unbind restores without replacing newer state", () async {
    final newest = _service(name: "Newest", revision: 4);
    harness.respond(_unbindSubject, (data) {
      harness.notifier.observe(newest);
      throw StateError("transport failed");
    });

    await expectLater(
      harness.container
          .read(servicesProvider.notifier)
          .deleteService(_service().serviceId),
      throwsA(isA<StateError>()),
    );

    expect(harness.container.read(servicesProvider).requireValue, [newest]);
    expect(reports, hasLength(1));
    expect(reports.single.context.toString(), "while deleting a service");
  });
}
