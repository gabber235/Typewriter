import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/editor_fixture.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");

skir.DataValue _value(String title) =>
    recordEditorValue({"title": skir.DataValue.wrapStringValue(title)});

final _fieldTypes = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};

EditorSnapshot _snapshot({required String title, required int revision}) =>
    FakeEditorSnapshot(
      recordEditorDocument(
        {"title": skir.DataValue.wrapStringValue(title)},
        _fieldTypes,
        revision,
      ),
      validation: acceptTestEditorMutation,
    );

void main() {
  test("same revision refresh adopts the authoritative value without sending the draft", () async {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    var sends = 0;
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(title: "Green", revision: 2),
      commit: (commit) async {
        sends++;
        return MutationConflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: _value("Green"),
        );
      },
    );
    final source = workspace.editor(
      ResourceEditorTarget(
        targetId: resource.key.identity,
        label: "Resource",
        resource: resource,
        snapshot: _snapshot(title: "Blue", revision: 2),
        commitPolicy: EditorCommitPolicy.applyResource,
      ),
    ) as TransactionalEditorSource;
    workspace.retain(resource.key);
    source.update(_title, skir.DataValue.wrapStringValue("Red"));

    expect(await source.flush(), isA<MutationUnavailable>());
    expect(source.document.confirmedValue, _value("Green"));
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Red"),
    );
    expect(source.hasWork, isTrue);
    expect(
      source.saveState(_title).phase,
      isIn([EditorSavePhase.conflict, EditorSavePhase.pending]),
    );
    expect(sends, 0);

    source.discardDraft();
    expect(source.document.confirmedValue, _value("Green"));
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Green"),
    );
    expect(source.saveState(_title).phase, EditorSavePhase.idle);
  });
}
