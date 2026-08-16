import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  final priority = DataPath.root.field("priority");

  testWidgets("typing in a numeric field keeps focus and saves on blur", (
    tester,
  ) async {
    final commits = <EditorCommit>[];
    final source = TransactionalEditorSource(
      document: _document(),
      debounce: Duration.zero,
      commit: (commit) async {
        commits.add(commit);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );
    addTearDown(source.dispose);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 500,
        child: SingleChildScrollView(child: EditorSurface(source: source)),
      ),
    );

    final numericField = find.byType(ValidatedTextField<DataValue>);
    final numericInput = find.descendant(
      of: numericField,
      matching: find.byType(EditableText),
    );
    await tester.tap(numericField);
    await tester.pump();

    for (final text in ["4", "42", "421"]) {
      tester.testTextInput.enterText(text);
      await tester.pump();
      expect(
        tester.widget<EditableText>(numericInput).focusNode.hasFocus,
        isTrue,
      );
    }

    expect(commits, isEmpty);
    expect(source.saveState(priority).phase, EditorSavePhase.pending);

    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(commits.single.changedPaths, {priority});
    expect(source.value(priority).valueOrNull, IntegerValue(BigInt.from(421)));
    expect(source.saveState(priority).phase, EditorSavePhase.saved);
    expect(find.text("Saved"), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}

EditorDocument _document() {
  return EditorDocument(
    rootType: RecordType(
      fields: {
        "title": const TypeField(name: "title", type: StringType()),
        "priority": const TypeField(
          name: "priority",
          type: IntegerType(width: IntegerWidth.signed32),
        ),
      },
    ),
    typeCatalog: const TypeCatalog([]),
    confirmedValue: RecordValue({
      "title": const StringValue("Greet the innkeeper"),
      "priority": IntegerValue(BigInt.two),
    }),
    revision: 0,
  );
}
