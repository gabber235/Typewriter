import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  for (final value in [
    skir.DataValue.wrapStringValue("ga"),
    skir.DataValue.unfilled,
  ]) {
    test(
      value == skir.DataValue.unfilled
          ? "unfinished Tag name saves and survives authoritative refresh"
          : "Tag name outside service identifier rules saves and survives refresh",
      () async {
        final tag = Tag(
          tagId: skir.ResourceId(value: "tag:save_policy"),
          name: "Main Quest",
          color: Colors.blue,
          parentIds: const [],
          placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
        );
        final document = fixtureAuthoringDocument(tags: [tag]);
        final transport = ScriptedAuthoringTransport(AsyncData(document));
        addTearDown(transport.dispose);
        final workspace = RealmEditing(
          persistence: transport.persistence,
          submissions: _workSession(),
          initial: document,
        );
        addTearDown(workspace.dispose);
        final location = skir.ValueLocation(
          resource: tag.tagId,
          path: editorRootPath.field("name"),
        );
        final result = workspace.edit(
          label: "Edit Tag name",
          policy: EditorCommitPolicy.applyResource,
          apply: (edit) => edit.set(location, value),
        );
        expect(result, isA<EditStaged>());
        expect(
          (workspace.document.read(
            location,
          ) as PortablePathValue<skir.DataValue>).value,
          value,
        );
        expect(
          const RealmEditModel().validateCommit(workspace.document),
          isEmpty,
        );
        final saving = workspace.save((result as EditStaged).group);
        await Future<void>.delayed(Duration.zero);
        expect(transport.requests, hasLength(1));
        final intent =
            transport.requests.single.edit.intents.single
                as skir.EditIntent_setValueWrapper;
        expect(intent.value.at, location);
        expect(intent.value.value, value);
        transport.confirm(0, workspace.document);
        await saving;
        await workspace.refreshConfirmed();
        expect(workspace.hasPendingWork, isFalse);
        expect(
          (workspace.document.read(
            location,
          ) as PortablePathValue<skir.DataValue>).value,
          value,
        );
      },
    );
  }

  test("Tag selection opens the shared authored inspector", () async {
    final tag = Tag(
      tagId: skir.ResourceId(value: "tag:test"),
      name: "Test Tag",
      color: Colors.blue,
      parentIds: const [],
      placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    );
    final document = fixtureAuthoringDocument(tags: [tag]);
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    final workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: _workSession(),
      initial: document,
    );
    addTearDown(workspace.dispose);
    final selection = AuthoringSelectableResource(
      id: AuthoringResourceIdentifier(
        organizationId: skir.recordId("organization:test"),
        realmId: skir.recordId("realm:test"),
        resourceId: tag.tagId,
      ),
      resource: document.entry(tag.tagId)!,
      workspace: workspace,
      commands: fixtureAuthoringCommands(transport),
    );
    final owners = InspectionBindings();
    addTearDown(owners.dispose);

    final inspection = selection.buildInspection(owners);

    expect(inspection.body, isA<AuthoredResourceInspection>());
    expect(inspection.host, isNull);
    expect(selection.capabilities, isEmpty);
    expect(workspace.document.entry(tag.tagId), isNotNull);
  });
}

ScopedWorkSession _workSession() {
  final session = ScopedWorkSession();
  addTearDown(session.dispose);
  return session;
}
