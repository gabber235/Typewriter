import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(scope: "realm", identity: "resource");
final _name = DataPath.root.field("name");
final _color = DataPath.root.field("color");

RecordValue _value(String name, int color) =>
    RecordValue({"name": name.asValue, "color": color.asValue});

ResourceEditorTarget _target() => fakeEditorTarget(
  targetId: _key.identity,
  scope: _key.scope,
  label: "Resource",
  document: EditorDocument(
    rootType: RecordType(
      fields: const {
        "name": TypeField(name: "name", type: StringType()),
        "color": TypeField(
          name: "color",
          type: IntegerType(width: IntegerWidth.signed32),
        ),
      },
    ),
    typeCatalog: const TypeCatalog([]),
    confirmedValue: _value("Canonical", 1),
    revision: 1,
  ),
  validation: acceptTestEditorMutation,
  commitPolicy: EditorCommitPolicy.applyResource,
  commit: (_) async => throw StateError("No save expected"),
);

void main() {
  test("projects only edited paths and tracks resource removal", () {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);

    expect(workspace.state.editorValues, isEmpty);

    final source = workspace.editor(_target())..update(_name, "Draft".asValue);

    final local = workspace.state.editorValues[_key];
    expect(local, isNotNull);
    expect(local!.editedPaths, {_name});
    expect(local.projectOnto(_value("Remote", 2)), _value("Draft", 2));

    source.discardDraft();
    expect(workspace.state.editorValues, isEmpty);
  });

  test("different resources retain structural identity", () {
    final first = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_name},
    );
    final same = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_name},
    );
    final different = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_color},
    );

    expect(first, same);
    expect(first, isNot(different));
  });
}
