import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(scope: "realm", identity: "resource");
final _name = editorRootPath.field("name");

void main() {
  test("a draft projects only its edited paths and leaves with the draft", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);

    expect(workspace.state.editorValues, isEmpty);

    final source =
        fakeEditorTarget(
            targetId: _key.identity,
            scope: _key.scope,
            label: "Resource",
            document: recordEditorDocument(
              {
                "name": skir.DataValue.wrapStringValue("Canonical"),
                "color": skir.DataValue.wrapInteger("1"),
              },
              {
                "name": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                "color": skir.TypeTemplate.wrapScalar(
                  skir.ScalarKind.createInteger(
                    width: skir.IntegerWidth.signedThirtyTwo,
                  ),
                ),
              },
              1,
            ),
            validation: acceptTestEditorMutation,
            commitPolicy: EditorCommitPolicy.applyResource,
            commit: (_) async => throw StateError("No save expected"),
          ).acquire(workspace)
          ..update(_name, skir.DataValue.wrapStringValue("Draft"));

    final local = workspace.state.editorValues[_key];
    expect(
      local?.projectOnto(
        recordEditorValue({
          "name": skir.DataValue.wrapStringValue("Remote"),
          "color": skir.DataValue.wrapInteger("2"),
        }),
      ),
      recordEditorValue({
        "name": skir.DataValue.wrapStringValue("Draft"),
        "color": skir.DataValue.wrapInteger("2"),
      }),
      reason: "the remote color survives, the drafted name wins",
    );

    source.discardDraft();
    expect(workspace.state.editorValues, isEmpty);
  });
}
