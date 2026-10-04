import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = DataPath.root.field("title");

RecordValue _value(String title) => RecordValue({"title": StringValue(title)});

EditorSnapshot _snapshot({required String title, required int revision}) =>
    FakeEditorSnapshot(
      EditorDocument(
        rootType: RecordType(
          fields: const {"title": TypeField(name: "title", type: StringType())},
        ),
        typeCatalog: const TypeCatalog([]),
        confirmedValue: _value(title),
        revision: revision,
      ),
      validation: acceptTestEditorMutation,
    );

void main() {
  test("same revision refresh adopts the authoritative value without sending the draft", () async {
    final workspace = LocalWorkSession();
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
    source.update(_title, const StringValue("Red"));

    expect(await source.flush(), isA<MutationUnavailable>());
    expect(source.document.confirmedValue, _value("Green"));
    expect(source.value(_title).valueOrNull, const StringValue("Red"));
    expect(source.hasWork, isTrue);
    expect(
      source.saveState(_title).phase,
      isIn([EditorSavePhase.conflict, EditorSavePhase.pending]),
    );
    expect(sends, 0);

    source.discardDraft();
    expect(source.document.confirmedValue, _value("Green"));
    expect(source.value(_title).valueOrNull, const StringValue("Green"));
    expect(source.saveState(_title).phase, EditorSavePhase.idle);
  });
}
