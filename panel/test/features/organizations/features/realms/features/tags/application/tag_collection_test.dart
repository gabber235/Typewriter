import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
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
    final workspace = AuthoringWorkspace(
      transport: transport,
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
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);

    final inspection = selection.buildInspection(owners);

    expect(inspection.body, isA<AuthoredResourceInspection>());
    expect(inspection.host, isNull);
    expect(selection.capabilities.single, isA<DeleteSelectionCapability>());
    await (selection.capabilities.single as DeleteSelectionCapability)
        .onDelete();
    expect(workspace.document.entry(tag.tagId), isNull);
  });
}
