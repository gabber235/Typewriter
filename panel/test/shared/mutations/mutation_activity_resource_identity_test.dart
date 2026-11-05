import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("an uncertain save never shows its request identity", (
    tester,
  ) async {
    const key = EditorResourceKey(scope: "test", identity: "uncertain");
    final snapshot = FakeEditorSnapshot(
      recordEditorDocument(
        {"name": skir.DataValue.wrapStringValue("canonical")},
        {"name": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
        1,
      ),
      validation: acceptTestEditorMutation,
    );
    final work = testWorkSession();
    final source = ValueEditingRegistration(
      targetId: key.identity,
      label: "Uncertain configuration",
      persistence: UncertainConfigurationResource(key, snapshot),
      snapshot: snapshot,
      commitPolicy: EditorCommitPolicy.applyResource,
    ).acquire(work);
    holdValueLease(work, key);
    source.update(
      editorRootPath.field("name"),
      skir.DataValue.wrapStringValue("local draft"),
    );
    expect(await source.flush(), isA<MutationUncertain>());

    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    await panel.activity.open("Needs attention");

    expect(
      panel.shows("The outcome is unknown. Local work is retained"),
      isTrue,
    );
    expect(
      panel.activity.entry("Uncertain configuration").hasDetails,
      isFalse,
      reason: "an uncertain outcome has no diagnostics to disclose",
    );
    expect(find.textContaining("not-a-uuid"), findsNothing);
    expect(find.bySemanticsLabel(RegExp("not-a-uuid")), findsNothing);
  });
}
