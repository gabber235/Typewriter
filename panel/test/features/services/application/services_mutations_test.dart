import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _scope = "cloud.to.user.ada.organization.acme";
const _bindSubject = "$_scope.services.bind";
const _updateSubject = "$_scope.services.update";
const _unbindSubject = "$_scope.services.unbind";
const _watchSubject = "$_scope.services.watch";
const _configureSubject = "$_scope.topology.configure";
final _organization = acme.organizationId;

final _service = service("service1", name: "original", status: null);

/// [_service] as a newer observation renamed it, at revision 4.
final _newest = service("service1", name: "newest", revision: 4, status: null);

final _host = paperHost(
  "paper",
  service: _service.serviceId,
  engines: ["paper"],
  state: skir.HostRuntimeState.defaultInstance,
);

/// Ada signed in to Acme, whose backend lists [_service] on [_host].
final _acme = [
  signedIn(ada, organization: acme),
  servicesBackend(
    services: [_service],
    topology: topologySnapshot(hosts: [_host]),
  ),
];

/// A submission the backend answered without confirming its outcome.
final _uncertain = isA<SubmissionException>().having(
  (error) => error.submission.result,
  "outcome",
  isA<SubmissionUncertain>(),
);

void main() {
  group("rename", () {
    test("a rename sends the name with the service's own revision and lists "
        "the confirmed service", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final confirmed = service(
        "service1",
        name: "updated",
        revision: 2,
        status: null,
      );
      skir.ServiceRename? sent;
      world.nats.registerHandler(_updateSubject, (data) {
        sent = skir.UpdateOrganizationServicesRequest.serializer
            .fromBytes(data)
            .renames
            .single;
        return skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapSuccess([confirmed]),
        );
      });

      final result = await services.rename(_service, "updated");

      expect(sent?.serviceId, _service.serviceId);
      expect(sent?.expectedRevision, 1);
      expect(sent?.name, "updated");
      expect(result, isA<MutationSuccess>());
      expect(await services.listed(), [confirmed]);
    });

    test("a delayed rename reply cannot replace a newer observation", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final newest = _newest;
      world.nats.registerHandler(_updateSubject, (_) {
        services.repository.acceptService(newest);
        return skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapSuccess([
            service("service1", name: "delayed", revision: 2, status: null),
          ]),
        );
      });

      final result = await services.rename(_service, "requested");

      expect(result, isA<MutationSuccess>());
      expect((result as MutationSuccess).revision, 2);
      expect(await services.listed(), [newest]);
    });

    test("renaming a deleted service reports it unavailable as deleted and "
        "keeps the listed service", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _updateSubject,
        (_) => skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapRefusedError([
            skir.RefusedServiceRename(
              serviceId: _service.serviceId,
              reason: skir.ServiceRenameRefusal.createServiceNotFoundError(),
            ),
          ]),
        ),
      );

      final result = await services.rename(_service, "updated");

      expect(
        result,
        isA<MutationUnavailable>().having(
          (unavailable) => unavailable.diagnostics.single.details,
          "details",
          {"editor.target": "deleted"},
        ),
      );
      expect(await services.listed(), [_service]);
    });

    test("a rejected name tells the author the naming rule on the name "
        "field", () async {
      final reports = captureFlutterErrors();
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _updateSubject,
        (_) => skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapRefusedError([
            skir.RefusedServiceRename(
              serviceId: _service.serviceId,
              reason: skir.ServiceRenameRefusal.wrapValidationError(
                skir.ServiceUpdateValidationError.nameInvalid,
              ),
            ),
          ]),
        ),
      );

      final result = await services.rename(_service, "updated");

      final diagnostic = (result as MutationInvalid).diagnostics.single;
      expect(diagnostic.path, editorRootPath.field("name"));
      expect(
        diagnostic.message,
        "Use at least three lowercase letters or digits separated by "
        "underscores",
      );
      expect(reports, isEmpty);
    });

    test("a rename conflict reports the actual revision and lists the actual "
        "service without reporting an error", () async {
      final reports = captureFlutterErrors();
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final actual = service(
        "service1",
        name: "canonical",
        revision: 3,
        status: null,
      );
      world.nats.registerHandler(
        _updateSubject,
        (_) => skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapRefusedError([
            skir.RefusedServiceRename(
              serviceId: _service.serviceId,
              reason: skir.ServiceRenameRefusal.createConflictError(
                expectedRevision: 1,
                actual: actual,
              ),
            ),
          ]),
        ),
      );

      final result = await services.rename(_service, "updated");

      final conflict = result as MutationConflict;
      expect(conflict.expectedRevision, 1);
      expect(conflict.actualRevision, 3);
      expect(await services.listed(), [actual]);
      expect(reports, isEmpty);
    });
  });

  group("bind", () {
    test("binding sends the registration token and lists the services the "
        "backend reports afterwards", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final bound = service("bound", name: "bound", status: null);
      skir.BindServiceRequest? sent;
      world.nats.registerHandler(_bindSubject, (data) {
        sent = skir.BindServiceRequest.serializer.fromBytes(data);
        return skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createSuccess(
            serviceId: "bound",
            serviceName: "bound",
            serviceRole: skir.ServiceRole.createHost(version: "1"),
          ),
        );
      });
      world.nats.registerHandler(
        _watchSubject,
        (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
          skir.WatchOrganizationServicesResponse.wrapList([_service, bound]),
        ),
      );

      (await services.execute(services.repository.bind("TOKEN12345")))
          .requireAcceptedBinding();

      expect(sent?.registrationToken, "TOKEN12345");
      expect(await services.listed(), [_service, bound]);
    });

    final rejections = {
      "an invalid token": (
        skir.BindServiceResponse.createInvalidRegistrationTokenError(),
        400,
      ),
      "an unknown organization": (
        skir.BindServiceResponse.createOrganizationNotFoundError(),
        404,
      ),
    };
    for (final MapEntry(key: reason, value: (response, code))
        in rejections.entries) {
      test("a bind rejected for $reason fails with $code", () async {
        final world = testWorld(_acme);
        final services = await world.watchedServicesOf(_organization);
        world.nats.registerHandler(
          _bindSubject,
          (_) => skir.BindServiceResponse.serializer.toBytes(response),
        );

        await expectLater(
          services
              .execute(services.repository.bind("TOKEN12345"))
              .then((response) => response.requireAcceptedBinding()),
          throwsA(
            isA<ApiException>().having((error) => error.code, "code", code),
          ),
        );
      });
    }

    test("a bind answered with an internal error stays uncertain", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _bindSubject,
        (_) => skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createInternalError(),
        ),
      );

      await expectLater(
        services.execute(services.repository.bind("TOKEN12345")),
        throwsA(_uncertain),
      );
    });

    test("an accepted bind whose refresh fails stays confirmed and reports "
        "the failed integration", () async {
      final reports = captureFlutterErrors();
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.container.listen(localWorkProvider, (_, _) {});
      world.nats.registerHandler(
        _bindSubject,
        (_) => skir.BindServiceResponse.serializer.toBytes(
          skir.BindServiceResponse.createSuccess(
            serviceId: "bound",
            serviceName: "bound",
            serviceRole: skir.ServiceRole.createHost(version: "1"),
          ),
        ),
      );
      world.nats.registerHandler(
        _watchSubject,
        (_) => throw StateError("refresh failed"),
      );

      final response = await services.execute(
        services.repository.bind("TOKEN12345"),
      );

      expect(response, isA<skir.BindServiceResponse_successWrapper>());
      final submission = (await world.container.eventually(
        localWorkProvider,
        (work) =>
            work.submissions.single.result != LocalWorkSubmissionResult.ready,
        description: "the integrated bind",
      )).submissions.single;
      expect(submission.result, LocalWorkSubmissionResult.confirmed);
      expect(submission.integrationFailed, isTrue);
      expect(reports.single.exception, isA<StateError>());
    });
  });

  group("unbind", () {
    test("unbinding sends the service id and removes the service", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      skir.UnbindServicesRequest? sent;
      world.nats.registerHandler(_unbindSubject, (data) {
        sent = skir.UnbindServicesRequest.serializer.fromBytes(data);
        return skir.UnbindServicesResponse.serializer.toBytes(
          skir.UnbindServicesResponse.createSuccess(),
        );
      });

      await ServiceUnbinding(
        services.repository,
        world.container.read(localWorkProvider.notifier),
      ).unbind([_service.serviceId]);

      expect(sent?.serviceIds, ["service1"]);
      expect(await services.listed(), isEmpty);
    });

    test("an unbind refused because the service is no longer bound says so "
        "and keeps the service", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _unbindSubject,
        (_) => skir.UnbindServicesResponse.serializer.toBytes(
          skir.UnbindServicesResponse.wrapRefusedError([
            skir.RefusedServiceUnbind(
              serviceId: "service1",
              reason: skir.ServiceUnbindRefusal.createServiceNotFoundError(),
            ),
          ]),
        ),
      );

      await expectLater(
        ServiceUnbinding(
          services.repository,
          world.container.read(localWorkProvider.notifier),
        ).unbind([_service.serviceId]),
        throwsA(
          isA<RefusedTargets>()
              .having(
                (refused) => refused.message,
                "message",
                "This service is no longer bound to the organization",
              )
              .having((refused) => refused.targets, "targets", {
                _service.serviceId,
              }),
        ),
      );
      expect(await services.listed(), [_service]);
    });

    test("an unbind answered with an internal error stays uncertain and keeps "
        "the service", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _unbindSubject,
        (_) => skir.UnbindServicesResponse.serializer.toBytes(
          skir.UnbindServicesResponse.createInternalError(),
        ),
      );

      await expectLater(
        services.execute(services.repository.unbind([_service.serviceId])),
        throwsA(_uncertain),
      );
      expect(await services.listed(), [_service]);
    });

    test("an unbind lost in transport keeps the newer observation", () async {
      final reports = captureFlutterErrors();
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final newest = _newest;
      world.nats.registerHandler(_unbindSubject, (_) {
        services.repository.acceptService(newest);
        throw StateError("transport failed");
      });

      await expectLater(
        services.execute(services.repository.unbind([_service.serviceId])),
        throwsA(isA<SubmissionException>()),
      );

      expect(await services.listed(), [newest]);
      expect(reports, isEmpty);
    });
  });

  group("host Apply", () {
    test("an invalid configuration rejection shows the server's message as "
        "an invalid draft", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      world.nats.registerHandler(
        _configureSubject,
        (_) => skir.ConfigureServiceHostsResponse.serializer.toBytes(
          skir.ConfigureServiceHostsResponse.wrapRefusedError([
            skir.RefusedHostConfiguration(
              hostId: _host.hostId,
              reason:
                  skir.HostConfigurationRefusal.createInvalidConfigurationError(
                    message: "The Realm needs a primary engine",
                  ),
            ),
          ]),
        ),
      );

      final result = await services.applyHost(_host);

      expect(
        (result as MutationInvalid).diagnostics.single.message,
        "The Realm needs a primary engine",
      );
    });

    test("an Apply conflict reports the actual revision and the value a "
        "refresh would show", () async {
      final world = testWorld(_acme);
      final services = await world.watchedServicesOf(_organization);
      final actualHost = (_host.toMutable()..revision = 3).toFrozen();
      final actualRealm = skir.RealmInstance(
        realmId: skir.recordId("realm_instance:paper"),
        ownerHost: skir.OwnerHost(id: _host.hostId, name: "paper"),
        revision: 1,
        targetEngine: skir.EngineTarget(
          engineId: "paper",
          versionConstraint: "*",
        ),
        state: skir.ChildRuntimeState.defaultInstance,
      );
      world.nats.registerHandler(
        _configureSubject,
        (_) => skir.ConfigureServiceHostsResponse.serializer.toBytes(
          skir.ConfigureServiceHostsResponse.wrapRefusedError([
            skir.RefusedHostConfiguration(
              hostId: _host.hostId,
              reason: skir.HostConfigurationRefusal.createConflictError(
                actual: hostConfiguration(actualHost, realm: actualRealm),
              ),
            ),
          ]),
        ),
      );

      final conflict = await services.applyHost(_host) as MutationConflict;

      expect(conflict.expectedRevision, 1);
      expect(conflict.actualRevision, 3);
      expect(
        conflict.actualValue,
        HostEditorSnapshot(
          actualHost,
          topologySnapshot(hosts: [actualHost], realms: [actualRealm]),
        ).document.confirmedValue,
      );
    });

    final unavailable = {
      "an incompatible engine": () =>
          skir.HostConfigurationRefusal.createIncompatibleEngineError(
            target: skir.EngineTarget(
              engineId: "fabric",
              versionConstraint: "*",
            ),
          ),
      "an unknown Realm": () =>
          skir.HostConfigurationRefusal.createRealmNotFoundError(
            realmId: skir.recordId("realm_instance:gone"),
          ),
    };
    for (final MapEntry(key: reason, value: response) in unavailable.entries) {
      test("an Apply rejected for $reason reports Apply unavailable", () async {
        final world = testWorld(_acme);
        final services = await world.watchedServicesOf(_organization);
        world.nats.registerHandler(
          _configureSubject,
          (_) => skir.ConfigureServiceHostsResponse.serializer.toBytes(
            skir.ConfigureServiceHostsResponse.wrapRefusedError([
              skir.RefusedHostConfiguration(
                hostId: _host.hostId,
                reason: response(),
              ),
            ]),
          ),
        );

        expect(await services.applyHost(_host), isA<MutationUnavailable>());
      });
    }
  });

  group("lost reply", () {
    final renamed = service(
      "service1",
      name: "requested",
      revision: 2,
      status: null,
    );
    final applied = (_host.toMutable()..revision = 2).toFrozen();
    final saves = {
      "a rename": (
        subject: _updateSubject,
        reply: skir.UpdateOrganizationServicesResponse.serializer.toBytes(
          skir.UpdateOrganizationServicesResponse.wrapSuccess([renamed]),
        ),
        save: (OrganizationServices services) =>
            services.rename(_service, "requested"),
        saved: (OrganizationServices services) => services.listed(),
        expected: [renamed],
      ),
      "a host Apply": (
        subject: _configureSubject,
        reply: skir.ConfigureServiceHostsResponse.serializer.toBytes(
          skir.ConfigureServiceHostsResponse.wrapSuccess([
            hostConfiguration(applied),
          ]),
        ),
        save: (OrganizationServices services) => services.applyHost(_host),
        saved: (OrganizationServices services) async =>
            (await services.watchTopology()).hosts,
        expected: [applied],
      ),
    };
    for (final MapEntry(key: name, value: save) in saves.entries) {
      test("$name whose reply was lost settles saved from the Retry's reply "
          "without needing attention", () async {
        final world = testWorld(_acme);
        final services = await world.watchedServicesOf(_organization);
        await services.watchTopology();
        var lost = false;
        world.nats.registerHandler(save.subject, (_) {
          if (lost) return save.reply;
          lost = true;
          throw StateError("transport failed");
        });

        await expectLater(save.save(services), throwsA(_uncertain));
        final submission = world.container
            .read(localWorkProvider)
            .submissions
            .single;
        await world.container
            .read(localWorkControllerProvider)
            .retrySubmission(submission.id);

        final settled = (await world.container.eventually(
          localWorkProvider,
          (work) =>
              work.submissions.single.result != LocalWorkSubmissionResult.ready,
          description: "the retried save settling",
        )).submissions.single;
        expect(settled.result, LocalWorkSubmissionResult.confirmed);
        expect(settled.integrationFailed, isFalse);
        expect(settled.message, isNull);
        expect(await save.saved(services), save.expected);
      });
    }
  });

  group("signed out", () {
    final mutations = <String, Future<Object?> Function(World world)>{
      "a bind": (world) => world
          .servicesOf(_organization)
          .execute(
            world.servicesOf(_organization).repository.bind("TOKEN12345"),
          ),
      "a rename": (world) =>
          world.servicesOf(_organization).rename(_service, "updated"),
      "an unbind": (world) => world
          .servicesOf(_organization)
          .execute(
            world.servicesOf(_organization).repository.unbind([
              _service.serviceId,
            ]),
          ),
    };
    for (final MapEntry(key: mutation, value: run) in mutations.entries) {
      test("$mutation is refused as unauthenticated before any request", () {
        final world = testWorld([
          servicesBackend(services: [_service]),
        ]);

        expect(
          () => run(world),
          throwsA(
            isA<ApiException>().having((error) => error.code, "code", 401),
          ),
        );
        expect(world.nats.connected, isFalse);
      });
    }
  });
}
