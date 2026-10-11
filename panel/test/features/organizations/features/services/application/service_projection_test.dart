import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _organization = skir.recordId("organization:projection");
final _firstId = skir.recordId("service:first");
final _secondId = skir.recordId("service:second");

Service _service(
  skir.RecordId id,
  String name, {
  int revision = 4,
  DateTime? lastSeen,
}) => Service(
  serviceId: id,
  revision: revision,
  name: name,
  role: HostServiceRole(version: "1"),
  createdAt: DateTime.utc(2026),
  organization: _organization,
  state: ServiceState(
    status: ServiceStateStatus.online,
    lastSeen: lastSeen ?? DateTime.utc(2026, 1, 1),
  ),
);

void main() {
  test(
    "service projection overlays identity and preserves canonical state",
    () {
      final canonical = _service(_firstId, "Canonical");
      final local = LocalEditorValue(
        value: skir.DataValue.createRecord(
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("Edited"),
            ),
          ],
        ),
        editedPaths: {editorRootPath.field("name")},
      );

      final projected = canonical.projected(local);

      expect(projected.name, "Edited");
      expect(projected.revision, canonical.revision);
      expect(projected.state, canonical.state);
      expect(projected.lastSeen, canonical.lastSeen);
    },
  );

  test(
    "single service projection does not leak another resource draft",
    () async {
      final first = _service(_firstId, "First");
      final second = _service(_secondId, "Second");
      final container = ProviderContainer.test(
        overrides: [
          organizationIdProvider.overrideWithValue(_organization),
          canonicalOrganizationServicesProvider(_organization)
              .overrideWith(() => _SeededServices([first, second])),
        ],
      );
      addTearDown(container.dispose);
      final workspace = container.read(localWorkControllerProvider);

      final target = fakeEditorTarget(
        targetId: _firstId,
        scope: EditorResourceScope(organizationId: _organization),
        label: "First",
        document: first.editorSnapshot.document,
        validation: acceptTestEditorMutation,
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (_) async => throw StateError("No save expected"),
      );
      workspace
          .editor(target)
          .update(
            editorRootPath.field("name"),
            skir.DataValue.wrapStringValue("Edited first"),
          );
      final firstProjection = container.listen(
        projectedServiceProvider(_firstId),
        (_, _) {},
      );
      final secondProjection = container.listen(
        projectedServiceProvider(_secondId),
        (_, _) {},
      );
      final listProjection = container.listen(
        projectedServicesProvider,
        (_, _) {},
      );
      addTearDown(firstProjection.close);
      addTearDown(secondProjection.close);
      addTearDown(listProjection.close);
      await container.read(canonicalServicesProvider.future);
      await container.read(canonicalServiceProvider(_firstId).future);
      await container.read(canonicalServiceProvider(_secondId).future);
      await container.pump();

      expect(
        container.read(projectedServiceProvider(_firstId)).requireValue?.name,
        "Edited first",
      );
      expect(
        container.read(projectedServiceProvider(_secondId)).requireValue?.name,
        "Second",
      );
      expect(
        container
            .read(projectedServicesProvider)
            .requireValue
            .map((service) => service.name),
        ["Edited first", "Second"],
      );
    },
  );
}

class _SeededServices extends CanonicalOrganizationServices {
  _SeededServices(this.services);
  final List<Service> services;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) =>
      Stream.value(services);
}
