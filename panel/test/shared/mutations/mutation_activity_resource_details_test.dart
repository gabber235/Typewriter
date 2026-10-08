import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../support/test_utils.dart";

Future<void> _setSurface(WidgetTester tester, {required bool mobile}) async {
  final size = Size(mobile ? 390 : 1280, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _openActivity(
  WidgetTester tester,
  LocalWorkSession workspace, {
  required bool mobile,
}) async {
  await tester.pumpTestApp(
    child: Scaffold(
      appBar: AppBar(
        actions: [LocalWorkSessionActivityView(controller: workspace)],
      ),
    ),
  );
  await tester.tap(
    mobile ? find.byTooltip("Needs attention") : find.text("Needs attention"),
  );
  await tester.pumpAndSettle();
}

EditorDocument _document(String field, String value) => EditorDocument(
  rootType: RecordType(
    fields: {field: TypeField(name: field, type: StringType())},
  ),
  typeCatalog: const TypeCatalog([]),
  confirmedValue: RecordValue({field: StringValue(value)}),
  revision: 1,
);

void _dismissSubmissions(LocalWorkSession workspace) {
  for (final submission in workspace.submissions) {
    workspace.dismiss(submission.id);
  }
}

void main() {
  for (final mobile in [false, true]) {
    testWidgets(
      "resource failure summary truncates collapsed and expands from body on "
      "${mobile ? "mobile" : "desktop"}",
      (tester) async {
        await _setSurface(tester, mobile: mobile);
        const key = EditorResourceKey(scope: "test", identity: "host");
        const diagnostic = TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Different values share the same revision and cannot be saved until the conflict is resolved",
          path: DataPath.root,
        );
        final document = _document("target", "paper@*");
        final workspace = LocalWorkSession();
        addTearDown(workspace.dispose);
        final source = workspace.editor(
          fakeEditorTarget(
            targetId: key.identity,
            scope: key.scope,
            label: "Paper Host configuration",
            document: document,
            validation: acceptTestEditorMutation,
            commitPolicy: EditorCommitPolicy.applyResource,
            commit: (_) async => MutationInvalid([diagnostic]),
          ),
        );
        workspace.retain(key);
        source.update(
          DataPath.root.field("target"),
          const StringValue("unsupported"),
        );
        expect(await source.flush(), isA<MutationInvalid>());

        await _openActivity(tester, workspace, mobile: mobile);
        expect(find.byKey(ValueKey(("resource", key))), findsOneWidget);
        final summary = "Save failed: ${diagnostic.message}";
        final summaryFinder = find.text(summary);
        expect(summaryFinder, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(summaryFinder).didExceedMaxLines,
          isTrue,
        );
        expect(find.text("Code"), findsNothing);
        expect(find.text("Show details"), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
        expect(find.text("Retry save"), findsOneWidget);
        expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
        expect(
          tester.getBottomRight(find.byIcon(Icons.copy_outlined)).dx,
          lessThanOrEqualTo(mobile ? 390 : 1280),
        );

        await tester.tap(summaryFinder);
        await tester.pumpAndSettle();
        expect(find.text("Code"), findsOneWidget);
        expect(find.text("invalidValue"), findsOneWidget);
        expect(find.text("Diagnostic path"), findsOneWidget);
        expect(find.text("unsupported"), findsNothing);
        expect(
          tester.renderObject<RenderParagraph>(summaryFinder).didExceedMaxLines,
          isFalse,
        );

        await tester.tap(summaryFinder);
        await tester.pumpAndSettle();
        expect(find.text("Code"), findsNothing);
        expect(
          tester.renderObject<RenderParagraph>(summaryFinder).didExceedMaxLines,
          isTrue,
        );
        _dismissSubmissions(workspace);
      },
    );
  }
  testWidgets(
    "failure actions copy a shareable report and keep discard on error",
    (tester) async {
      await _setSurface(tester, mobile: false);
      const key = EditorResourceKey(scope: "test", identity: "copy");
      final diagnostic = TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Choose a supported engine target",
        path: DataPath.root.field("target"),
      );
      final document = _document("target", "paper@*");
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      final source = workspace.editor(
        fakeEditorTarget(
          targetId: key.identity,
          scope: key.scope,
          label: "Paper Host configuration",
          document: document,
          validation: acceptTestEditorMutation,
          commitPolicy: EditorCommitPolicy.applyResource,
          commit: (_) async => MutationInvalid([diagnostic]),
        ),
      );
      workspace.retain(key);
      source.update(
        DataPath.root.field("target"),
        const StringValue("unsupported"),
      );
      expect(await source.flush(), isA<MutationInvalid>());

      String? clipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == "Clipboard.setData") {
            clipboardText =
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

      await _openActivity(tester, workspace, mobile: false);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(find.text("Retry save"), findsOneWidget);
      final discardFinder = find.widgetWithText(TextButton, "Discard");
      final discard = tester.widget<TextButton>(discardFinder);
      final context = tester.element(discardFinder);
      expect(
        discard.style!.foregroundColor!.resolve({}),
        context.theme.colorScheme.error,
      );

      final copy = tester.getCenter(find.byIcon(Icons.copy_outlined));
      final retry = tester.getCenter(find.text("Retry save"));
      final discardPosition = tester.getCenter(discardFinder);
      expect(copy.dx, lessThan(retry.dx));
      expect(retry.dx, lessThan(discardPosition.dx));

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();
      expect(clipboardText, isNotNull);
      expect(clipboardText, contains("Paper Host configuration"));
      expect(
        clipboardText,
        contains("Save failed: Choose a supported engine target"),
      );
      expect(clipboardText, contains("Phase: failed"));
      expect(
        clipboardText,
        contains("Reason: Choose a supported engine target"),
      );
      expect(clipboardText, contains("Code: invalidValue"));
      expect(clipboardText, contains(r"Diagnostic path: $.target"));
      ScaffoldMessenger.of(context).clearSnackBars();
      await tester.pumpAndSettle();
      _dismissSubmissions(workspace);
    },
  );

  testWidgets("resource contention details show safe retry metadata", (
    tester,
  ) async {
    await _setSurface(tester, mobile: false);
    const key = EditorResourceKey(scope: "test", identity: "contention");
    final document = _document("target", "canonical");
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final source = workspace.editor(
      fakeEditorTarget(
        targetId: key.identity,
        scope: key.scope,
        label: "Contended configuration",
        document: document,
        validation: acceptTestEditorMutation,
        commit: (commit) async => MutationConflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: commit.expectedRevision + 1,
          actualValue: document.confirmedValue,
        ),
      ),
    );
    workspace.retain(key);
    source.update(
      DataPath.root.field("target"),
      const StringValue("local value"),
    );
    final flush = source.flush();
    await tester.pump(const Duration(seconds: 10));
    expect(await flush, isA<MutationConflict>());

    await _openActivity(tester, workspace, mobile: false);
    expect(find.byKey(ValueKey(("resource", key))), findsOneWidget);
    expect(
      find.text("Changed repeatedly elsewhere. Retry when other edits stop."),
      findsOneWidget,
    );
    await tester.tap(
      find.text("Changed repeatedly elsewhere. Retry when other edits stop."),
    );
    await tester.pumpAndSettle();
    expect(find.text("Contention"), findsOneWidget);
    expect(find.text("versionMismatch"), findsOneWidget);
    expect(find.text("4 total"), findsOneWidget);
    expect(find.text("3 of 3"), findsOneWidget);
    expect(find.text("Expected version"), findsOneWidget);
    expect(find.text("Observed version"), findsOneWidget);
    expect(find.text("local value"), findsNothing);
  });

  testWidgets("ordinary resource drafts have no details disclosure", (
    tester,
  ) async {
    await _setSurface(tester, mobile: false);
    const key = EditorResourceKey(scope: "test", identity: "draft");
    final document = _document("name", "canonical");
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final source = workspace.editor(
      fakeEditorTarget(
        targetId: key.identity,
        scope: key.scope,
        label: "Draft configuration",
        document: document,
        validation: acceptTestEditorMutation,
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (_) async =>
            MutationSuccess(revision: 2, value: document.confirmedValue),
      ),
    );
    workspace.retain(key);
    source.update(
      DataPath.root.field("name"),
      const StringValue("local draft"),
    );

    await tester.pumpTestApp(
      child: Scaffold(
        appBar: AppBar(
          actions: [LocalWorkSessionActivityView(controller: workspace)],
        ),
      ),
    );
    await tester.tap(find.text("1 draft"));
    await tester.pumpAndSettle();

    expect(find.text("Configuration draft"), findsOneWidget);
  });
}
