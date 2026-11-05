import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _title = editorRootPath.field("title");
void main() {
  test("superseded interaction cannot cancel a later edit", () async {
    final source = fakeValueEditing(
      document: recordEditorDocument(
        {
          "title": skir.DataValue.wrapStringValue("Original"),
          "position": skir.DataValue.wrapInteger("0"),
        },
        {
          "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
          "position": skir.TypeTemplate.wrapScalar(
            skir.ScalarKind.createInteger(
              width: skir.IntegerWidth.signedThirtyTwo,
            ),
          ),
        },
        1,
      ),
      validation: (path, value) => EditorMutationResult.applied(value),
      debounce: const Duration(days: 1),
      commit: (commit) async =>
          MutationSuccess(revision: 3, value: commit.rootValue),
    );
    addTearDown(source.dispose);
    final earlier = source.beginInteraction(_title);
    source.update(_title, skir.DataValue.wrapStringValue("Earlier"));
    final later = source.beginInteraction(_title);
    source.update(_title, skir.DataValue.wrapStringValue("Later"));

    await later.commit();
    earlier.cancel();
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Later"),
    );
  });
}
