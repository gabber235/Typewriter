import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _bindSubject = "cloud.to.user.user1.organization.org1.services.bind";
const _updateSubject = "cloud.to.user.user1.organization.org1.services.update";
const _unbindSubject = "cloud.to.user.user1.organization.org1.services.unbind";
const _watchSubject = "cloud.to.user.user1.organization.org1.services.watch";
final _organizationId = skir.recordId("organization:org1");

skir.Service _service({String name = "Original", int revision = 1}) =>
    skir.Service(
      serviceId: skir.recordId("service:service1"),
      revision: revision,
      name: name,
      role: skir.ServiceRole.createHost(version: "1"),
      createdAt: DateTime.utc(2025),
      organization: null,
      registration: null,
      state: null,
    );

class _Harness {
  _Harness() {
    nats.registerHandler(
      _watchSubject,
      (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
        skir.WatchOrganizationServicesResponse.wrapList([_service()]),
      ),
    );
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWithValue(_organizationId),
        natsProvider.overrideWith(() => FakeNats(nats)),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;
  ProviderSubscription<AsyncValue<List<skir.Service>>>? subscription;

  Future<void> ready() async {
    subscription = container.listen(
      canonicalServicesProvider,
      (previous, next) {},
    );
    await container.read(canonicalServicesProvider.future);
  }

  void respond(String subject, Uint8List Function(Uint8List data) handler) {
    nats.registerHandler(subject, handler);
  }

  void observe(skir.Service service) => container
      .read(resourceRepositoriesProvider)
      .services(_organizationId)
      .acceptService(service);

  void dispose() {
    subscription?.close();
    container.dispose();
    nats.dispose();
  }
}

extension _ServiceRepositoryCommands on ProviderContainer {
  ServiceResourceRepository get _services =>
      read(resourceRepositoriesProvider).services(_organizationId);

  Future<TypedMutationResult> updateService(skir.Service service) {
    final snapshot = service.editorSnapshot;
    return read(localWorkControllerProvider).execute(
      ServiceEditPersistence(_services, service.serviceId).prepareValue(
        snapshot,
        EditorCommit(
          expectedRevision: service.revision,
          localRevision: 1,
          rootValue: service.identityValue,
          baseValue: snapshot.document.confirmedValue,
          changedPaths: {editorRootPath.field("name")},
          mutations: const [],
        ),
      ),
    );
  }

  Future<void> deleteService(skir.RecordId service) async {
    final response = await read(localWorkControllerProvider)
        .execute(_services.unbind(service));
    response.requireAcceptedUnbinding();
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

    final result = await harness.container.updateService(
      _service(name: "Updated"),
    );

    expect(result, isA<MutationInvalid>());
    expect(
      (result as MutationInvalid).diagnostics.single.message,
      "The service contains invalid values",
    );
    expect(reports, isEmpty);
  });

  test("accepted bind keeps snapshot refresh failure as integration", () async {
    final work = harness.container.listen(localWorkProvider, (_, _) {});
    addTearDown(work.close);
    harness
      ..respond(
        _bindSubject,
        (_) => skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createSuccess(
            serviceId: "service1",
            serviceName: "Service",
            serviceRole: skir.ServiceRole.createHost(version: "1"),
          ),
        ),
      )
      ..respond(_watchSubject, (_) => throw StateError("refresh failed"));

    final response = await harness.container
        .read(localWorkControllerProvider)
        .execute(
          harness.container
              .read(resourceRepositoriesProvider)
              .services(_organizationId)
              .bind("registration token"),
        );
    for (var attempt = 0; attempt < 10; attempt++) {
      await harness.container.pump();
      if (harness.container.read(localWorkProvider).submissions.single.result !=
          LocalWorkSubmissionResult.ready) {
        break;
      }
    }

    expect(response, isA<skir.BindServiceResponse_successWrapper>());
    final submission = harness.container
        .read(localWorkProvider)
        .submissions
        .single;
    expect(submission.result, LocalWorkSubmissionResult.confirmed);
    expect(submission.integrationFailed, isTrue);
    expect(reports.single.exception, isA<StateError>());
  });

  test("update preserves conflict details without reporting", () async {
    final actual = _service(name: "Canonical", revision: 3);
    harness.respond(
      _updateSubject,
      (data) => skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.createConflictError(
          expectedRevision: 1,
          actual: actual,
        ),
      ),
    );

    final result = await harness.container.updateService(
      _service(name: "Updated"),
    );

    expect(result, isA<MutationConflict>());
    final conflict = result as MutationConflict;
    expect(conflict.expectedRevision, 1);
    expect(conflict.actualRevision, 3);
    await harness.container.pump();
    expect(await harness.container.read(canonicalServicesProvider.future), [
      actual,
    ]);
    expect(reports, isEmpty);
  });

  test(
    "uncertain update preserves the cause and observation without resending",
    () async {
      final newest = _service(name: "Newest", revision: 4);
      harness.respond(_updateSubject, (data) {
        harness.observe(newest);
        throw StateError("transport failed");
      });

      await expectLater(
        harness.container.updateService(_service(name: "Requested")),
        throwsA(
          isA<SubmissionException<TypedMutationResult>>().having(
            (error) => error.submission.result,
            "retained outcome",
            isA<SubmissionUncertain<TypedMutationResult>>().having(
              (result) => result.cause,
              "cause",
              isA<StateError>(),
            ),
          ),
        ),
      );
      await harness.container.pump();
      expect(await harness.container.read(canonicalServicesProvider.future), [
        newest,
      ]);

      expect(reports, isEmpty);
      await harness.container.pump();
      final submission = harness.container
          .read(localWorkProvider)
          .submissions
          .single;
      expect(submission.result, LocalWorkSubmissionResult.uncertain);
      expect(submission.canReplay, isFalse);
      final requestsBefore = harness.nats.requests.length;
      await harness.container
          .read(localWorkControllerProvider)
          .retrySubmission(submission.id);
      expect(harness.nats.requests.length, requestsBefore);
    },
  );

  test("unexpected unbind restores without replacing newer state", () async {
    final newest = _service(name: "Newest", revision: 4);
    harness.respond(_unbindSubject, (data) {
      harness.observe(newest);
      throw StateError("transport failed");
    });

    await expectLater(
      harness.container.deleteService(_service().serviceId),
      throwsA(isA<SubmissionException>()),
    );

    await harness.container.pump();

    expect(await harness.container.read(canonicalServicesProvider.future), [
      newest,
    ]);
    expect(reports, isEmpty);
  });
}
