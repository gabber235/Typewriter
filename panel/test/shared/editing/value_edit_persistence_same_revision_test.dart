import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");

void main() {
  test("same revision refresh adopts the authoritative value without sending the draft", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    var sends = 0;
    final resource = ScriptedValuePersistence(
      key: _key,
      current: savedTitleSnapshot(title: "Green", revision: 2),
      commit: (commit) async {
        sends++;
        return MutationConflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: titleValue("Green"),
        );
      },
    );
    final source = ValueEditingRegistration(
      targetId: resource.key.identity,
      label: "Resource",
      persistence: resource,
      snapshot: savedTitleSnapshot(title: "Blue", revision: 2),
      commitPolicy: EditorCommitPolicy.applyResource,
    ).acquire(workspace);
    addTearDown(
      workspace
          .lease(WorkDriverId(domain: "value", scope: resource.key))
          .release,
    );
    source.update(_title, skir.DataValue.wrapStringValue("Red"));

    expect(await source.flush(), isA<MutationUnavailable>());
    expect(source.document.confirmedValue, titleValue("Green"));
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Red"),
    );
    expect(source.hasWork, isTrue);
    expect(source.saveState(_title).phase, EditorSavePhase.conflict);
    expect(sends, 0);

    source.discardDraft();
    expect(source.document.confirmedValue, titleValue("Green"));
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Green"),
    );
    expect(source.saveState(_title).phase, EditorSavePhase.idle);
  });
}
