import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../support/provider_test_utils.dart";
import "../../../../../support/test_utils.dart";

part "topology_selection_removal_test_cases.dart";
part "host_apply_test_cases.dart";
part "host_target_selection_test_cases.dart";
part "resource_connection_test_cases.dart";
part "service_host_selectable_test_support.dart";

const _updateSubject = "cloud.to.user.user1.organization.org1.services.update";
const _configureSubject =
    "cloud.to.user.user1.organization.org1.topology.configure";
final _organizationId = skir.recordId("organization:org1");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _testTopologySelectionRemoval();
  _testHostApply();
  _testHostTargetSelection();
  _testResourceConnections();

  test("host presentation owns separate runtime and resource inputs", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);
    final content = _buildInspection(harness, owners);
    final edits = owners.workspace.resources.values
        .map((resource) => resource.source)
        .toList();
    expect(edits, hasLength(2));
    expect(edits.map((owner) => owner.document.revision), [1, 1]);
    expect(identical(edits[0], edits[1]), isFalse);
    expect(
      content.host!.document.bindings.values.where(
        (binding) => !binding.editable,
      ),
      isNotEmpty,
    );
  });

  test("service save carries only identity and its own revision", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    skir.UpdateOrganizationServiceRequest? request;
    harness.respond(_updateSubject, (data) {
      request = skir.UpdateOrganizationServiceRequest.serializer.fromBytes(
        data,
      );
      return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.wrapSuccess(
          harness.service.copyWith(revision: 2, name: "renamed").toSkir(),
        ),
      );
    });
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);

    _buildInspection(harness, owners);
    final owner = _identitySource(owners)
      ..update(DataPath.root.field("name"), const StringValue("renamed"));
    final result = await owner.flush() as MutationSuccess;
    expect(request!.name, "renamed");
    expect(result.revision, 2);
    expect((result.value as RecordValue).fields.keys, ["name"]);

    expect(harness.nats.requests.map((entry) => entry.subject), [
      "cloud.to.user.user1.organization.org1.services.watch",
      _updateSubject,
    ]);
  });

  test("service portable host preserves the backend editor owner", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    skir.UpdateOrganizationServiceRequest? request;
    harness.respond(_updateSubject, (data) {
      request = skir.UpdateOrganizationServiceRequest.serializer.fromBytes(
        data,
      );
      return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.wrapSuccess(
          harness.service.copyWith(revision: 2, name: "portable_name").toSkir(),
        ),
      );
    });
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);
    final host = _buildInspection(harness, owners).host!;
    final editable = host.document.bindings.entries.singleWhere(
      (entry) => entry.key.value == "service.identity.name",
    );

    final result = await host.write(
      skir.BindingRef(
        bindingId: editable.key,
        path: skir.ValuePath(segments: const []),
      ),
      skir.DataValue.wrapStringValue("portable_name"),
    );
    expect(result, isA<PortablePresentationWriteApplied>());

    final saved = await owners.flush();
    expect(saved.values, contains(isA<MutationSuccess>()));
    expect(request!.name, "portable_name");
    expect(request!.expectedRevision, 1);
  });

  test("service runtime bindings stay read only", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);
    final host = _buildInspection(harness, owners).host!;
    final runtime = host.document.bindings.entries.firstWhere(
      (entry) => !entry.value.editable,
    );

    expect(
      await host.write(
        skir.BindingRef(
          bindingId: runtime.key,
          path: skir.ValuePath(segments: const []),
        ),
        skir.DataValue.wrapStringValue("changed"),
      ),
      isA<PortablePresentationWriteRejected>(),
    );
  });

  test("configuration saves only the host transaction", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    skir.ConfigureServiceHostRequest? request;
    harness.respond(_configureSubject, (data) {
      request = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
      return skir.ConfigureServiceHostResponse.serializer.toBytes(
        skir.ConfigureServiceHostResponse.createSuccess(
          removedResources: [],
          host: _hostWithRevision(harness.host, 2),
          realm: harness.realm,
          engine: null,
        ),
      );
    });
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);

    _buildInspection(harness, owners);
    final owner = _configurationSource(owners)
      ..update(
        DataPath.root.field("realm"),
        PolymorphicValue(
          concreteType: const ResolvedTypeRef(
            id: QualifiedTypeId(namespace: "panel.host", name: "RealmHosted"),
            revision: 1,
          ),
          value: RecordValue({"target": StringValue("paper@*")}),
        ),
      );

    final result = await owner.flush() as MutationSuccess;
    expect(request!.execution.realm, isNotNull);
    expect(result.revision, 2);
    expect(
      (result.value as RecordValue).fields.containsKey("service"),
      isFalse,
    );
    expect(harness.nats.requests.map((entry) => entry.subject), [
      "cloud.to.user.user1.organization.org1.topology.watch",
      _configureSubject,
    ]);
  });

  test("service and host share one portable identity editor", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    final sessionSubscription = harness.container.listen(
      inspectionSessionProvider,
      (_, _) {},
    );
    addTearDown(sessionSubscription.close);
    final session = harness.container.read(inspectionSessionProvider);

    harness.container.read(selectionProvider.notifier).selectAll([
      ServiceIdentifier(harness.service.serviceId),
      ServiceHostIdentifier(harness.host.hostId),
    ]);
    await waitForProvider(
      harness.container,
      inspectedSelectionProvider,
      (value) => value.hasValue && value.requireValue.length == 2,
      description: "mixed service and host inspection",
    );
    await Future<void>.delayed(Duration.zero);

    expect(session.hosts, hasLength(1));
    expect(session.owners.workspace.resources, hasLength(1));
    expect(
      session.hosts.single.document.bindings.keys.map((id) => id.value),
      contains("service.identity.name"),
    );
  });

  test(
    "multiple hosts share identity and retain configuration editors",
    () async {
      final harness = await _Harness.create(includeSecondHost: true);
      addTearDown(harness.dispose);
      final sessionSubscription = harness.container.listen(
        inspectionSessionProvider,
        (_, _) {},
      );
      addTearDown(sessionSubscription.close);
      final session = harness.container.read(inspectionSessionProvider);

      harness.container.read(selectionProvider.notifier).selectAll([
        ServiceHostIdentifier(harness.host.hostId),
        ServiceHostIdentifier(harness.secondHost!.hostId),
      ]);
      await waitForProvider(
        harness.container,
        inspectedSelectionProvider,
        (value) => value.hasValue && value.requireValue.length == 2,
        description: "multiple host inspection",
      );
      await Future<void>.delayed(Duration.zero);

      expect(session.hosts, hasLength(2));
      expect(session.owners.workspace.resources, hasLength(3));
      expect(
        session.hosts
            .expand((host) => host.document.bindings.keys)
            .map((id) => id.value),
        containsAll([
          "service.identity.name",
          "host.configuration.realm.enabled",
        ]),
      );
    },
  );
}
