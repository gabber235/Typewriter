import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test("Tag selection opens the canonical authored inspector", () async {
    final session = AuthoringSessionMock();
    final tag = Tag(
      tagId: skir.ResourceId(value: "tag:test"),
      name: "Test Tag",
      color: Colors.blue,
      parentIds: const [],
      placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    );
    var deleted = false;
    final selection = TagSelectable(
      onDelete: () async => deleted = true,
      id: TagIdentifier(tag.tagId),
      tag: tag,
      draft: session.initial.draft!,
      catalog: session.initial.catalog!,
      session: session,
    );
    final owners = EditorOwnerRegistry();
    addTearDown(owners.dispose);

    final inspection = selection.buildInspection(owners);

    expect(inspection.body, isA<AuthoredResourceInspection>());
    expect(inspection.host, isNull);
    expect(selection.capabilities.single, isA<DeleteSelectionCapability>());
    await (selection.capabilities.single as DeleteSelectionCapability)
        .onDelete();
    expect(deleted, isTrue);
  });
}
