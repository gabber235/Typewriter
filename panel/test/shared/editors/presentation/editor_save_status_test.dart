import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final entry in const {
    EditorSavePhase.pending: "Pending",
    EditorSavePhase.saving: "Saving",
    EditorSavePhase.saved: "Saved",
    EditorSavePhase.sessionOnly: "Session only",
    EditorSavePhase.failed: "Save failed",
    EditorSavePhase.conflict: "Changed elsewhere",
    EditorSavePhase.repeatedContention: "Changed repeatedly elsewhere",
    EditorSavePhase.deletedElsewhere: "Deleted elsewhere",
  }.entries) {
    testWidgets("renders ${entry.key.name}", (tester) async {
      await tester.pumpTestApp(
        child: EditorSaveStatus(state: EditorSaveState(phase: entry.key)),
      );

      expect(find.text(entry.value), findsOneWidget);
    });
  }

  testWidgets("exposes conflict choices and retry actions", (tester) async {
    var usedRemote = false;
    await tester.pumpTestApp(
      child: EditorSaveStatus(
        state: const EditorSaveState(phase: EditorSavePhase.conflict),
        onUseRemote: () async => usedRemote = true,
      ),
    );

    await tester.tap(find.text("Use theirs"));
    expect(usedRemote, isTrue);

    var retried = false;
    await tester.pumpTestApp(
      child: EditorSaveStatus(
        state: const EditorSaveState(phase: EditorSavePhase.repeatedContention),
        onRetry: () async => retried = true,
      ),
    );
    await tester.tap(find.byType(LoadingIconButton));
    expect(retried, isTrue);
  });
}
