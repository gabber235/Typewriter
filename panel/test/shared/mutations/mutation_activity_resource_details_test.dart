import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const phone = Size(390, 800);
  final target = editorRootPath.field("target");

  for (final mobile in [false, true]) {
    testWidgets("a failure summary expands from its header and collapses "
        "again on ${mobile ? "mobile" : "desktop"}", (tester) async {
      final diagnostic = EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message:
            "Different values share the same revision and cannot be saved "
            "until the conflict is resolved",
        path: editorRootPath,
      );
      final work = await rejectedWork("Paper Host configuration", [diagnostic]);
      final panel = await tester.pumpPanel([
        if (mobile) window(phone),
      ], at: saveActivityOf(work));
      await panel.activity.open("Needs attention");
      final entry = panel.activity.entry("Paper Host configuration");
      final summary = find.text("Save failed: ${diagnostic.message}");
      expect(entry.hasDetails, isTrue);
      expect(entry.isExpanded, isFalse);
      expect(panel.shows("Code"), isFalse);
      final collapsed = tester.getSize(summary).height;

      await entry.toggleDetails();
      expect(entry.isExpanded, isTrue);
      expect(panel.shows("invalidValue"), isTrue);
      expect(panel.shows("Diagnostic path"), isTrue);
      expect(panel.shows("unsupported"), isFalse, reason: "drafts stay out");
      expect(
        tester.getSize(summary).height,
        greaterThan(collapsed),
        reason: "the expanded summary shows every line",
      );

      await entry.toggleDetails();
      expect(entry.isExpanded, isFalse);
      expect(panel.shows("Code"), isFalse);
      expect(tester.getSize(summary).height, collapsed);
    });

    testWidgets("failure actions stay on screen on "
        "${mobile ? "mobile" : "desktop"}", (tester) async {
      final work = await rejectedWork("Paper Host configuration", [
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidValue,
          message: "Choose a supported engine target",
          path: target,
        ),
      ]);
      final panel = await tester.pumpPanel([
        if (mobile) window(phone),
      ], at: saveActivityOf(work));
      await panel.activity.open("Needs attention");

      final width = mobile ? phone.width : desktopWindow.width;
      for (final action in [
        find.tooltip("Copy problem report"),
        find.text("Retry"),
        find.text("Discard"),
      ]) {
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
    });
  }

  testWidgets("copying a failure puts a shareable report on the clipboard", (
    tester,
  ) async {
    final work = await rejectedWork("Paper Host configuration", [
      EditorDiagnostic(
        code: EditorDiagnosticCode.invalidValue,
        message: "Choose a supported engine target",
        path: target,
      ),
    ]);
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "Clipboard.setData") {
          clipboard =
              (call.arguments as Map<Object?, Object?>)["text"] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    await panel.activity.open("Needs attention");

    await panel.activity.entry("Paper Host configuration").copyReport();

    expect(panel.shows("Problem copied to clipboard"), isTrue);
    expect(
      clipboard,
      allOf([
        contains("Paper Host configuration"),
        contains("Save failed: Choose a supported engine target"),
        contains("Phase: failed"),
        contains("Reason: Choose a supported engine target"),
        contains("Code: invalidValue"),
        contains(r"Diagnostic path: $.target"),
      ]),
    );
    expect(clipboard, isNot(contains("unsupported")), reason: "no draft data");
  });

  testWidgets("resource contention details show safe retry metadata", (
    tester,
  ) async {
    final work = testWorkSession();
    final source = editedResource(
      work,
      "Contended configuration",
      draft: "local value",
      policy: EditorCommitPolicy.autosaveChanges,
      commit: (commit) async => MutationConflict(
        expectedRevision: commit.expectedRevision,
        actualRevision: commit.expectedRevision + 1,
        actualValue: recordEditorValue({
          "target": skir.DataValue.wrapStringValue("paper@*"),
        }),
      ),
    );
    final flush = source.flush();
    await tester.pump(const Duration(seconds: 10));
    expect(await flush, isA<MutationUnavailable>());
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    await panel.activity.open("Needs attention");

    final entry = panel.activity.entry("Contended configuration");
    expect(
      panel.shows(
        "The resource changed repeatedly. Retry when other edits stop",
      ),
      isTrue,
    );
    await entry.toggleDetails();
    for (final fact in [
      "Contention",
      "versionMismatch",
      "4 total",
      "Retries",
      "3",
      "Expected version",
      "Observed version",
    ]) {
      expect(panel.shows(fact), isTrue, reason: fact);
    }
    expect(panel.shows("local value"), isFalse, reason: "drafts stay out");
  });

  testWidgets("ordinary resource drafts have no details disclosure", (
    tester,
  ) async {
    final work = testWorkSession();
    editedResource(
      work,
      "Draft configuration",
      draft: "local draft",
      commit: (_) async => throw StateError("No save expected"),
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    await panel.activity.open("1 draft");

    expect(panel.shows("Changes await applying"), isTrue);
    final entry = panel.activity.entry("Draft configuration");
    expect(entry.hasDetails, isFalse);
    await panel.tapOn(find.text("Changes await applying"));
    expect(panel.shows("Code"), isFalse);
    expect(find.tooltip("Copy problem report"), findsNothing);
  });
}
