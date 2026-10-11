import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../support/test_utils.dart";

ValueEditing _owner({EditorCommitter? commit}) => ValueEditing(
  document: EditorDocument(
    rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    confirmedValue: skir.DataValue.wrapStringValue("Saved"),
    revision: 1,
  ),
  validation: (path, value) => EditorMutationResult.applied(value),
  commitPolicy: EditorCommitPolicy.applyResource,
  commit: commit,
);
void main() {
  testWidgets(
    "Apply is hidden when clean, appears for edits, and hides after revert or acceptance",
    (tester) async {
      final owner = _owner();
      final control = owner.bindControl();
      addTearDown(control.dispose);
      addTearDown(owner.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: control)),
      );
      expect(find.text("Apply"), findsNothing);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      expect(find.text("Apply"), findsOneWidget);
      expect(find.text("Discard"), findsOneWidget);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Saved"));
      await tester.pump();
      expect(find.text("Apply"), findsNothing);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(find.text("Apply"), findsNothing);
      expect(
        owner.document.confirmedValue,
        skir.DataValue.wrapStringValue("Draft"),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
    },
  );
  testWidgets(
    "unknown delivery retains disabled Apply and never offers unsupported retry",
    (tester) async {
      var sends = 0;
      final owner = _owner(
        commit: (_) async {
          sends++;
          throw TimeoutException("Lost response");
        },
      );
      final control = owner.bindControl();
      addTearDown(control.dispose);
      addTearDown(owner.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: control)),
      );
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text("Retry"), findsNothing);
      expect(find.text("Discard"), findsNothing);
      expect(find.text("Refresh"), findsOneWidget);
      expect(sends, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
    },
  );
  testWidgets("Apply acts only on its bound owner", (tester) async {
    final first = _owner();
    final other = _owner();
    final control = first.bindControl();
    addTearDown(control.dispose);
    addTearDown(first.dispose);
    addTearDown(other.dispose);
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    other.update(editorRootPath, skir.DataValue.wrapStringValue("Other"));
    await tester.pumpTestApp(
      child: Scaffold(body: ApplyControls(control: control)),
    );
    await tester.tap(find.text("Apply"));
    await tester.pumpAndSettle();
    expect(first.hasWork, isFalse);
    expect(other.hasWork, isTrue);
    expect(other.document.revision, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    other.dispose();
  });
}
