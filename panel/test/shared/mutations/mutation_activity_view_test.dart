import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../support/test_utils.dart";

void main() {
  const screenshotDirectory = String.fromEnvironment(
    "SAVE_ACTIVITY_SCREENSHOTS",
  );
  if (screenshotDirectory.isNotEmpty) {
    TestWidgetsFlutterBinding.ensureInitialized();
    setUpAll(() async {
      for (final (family, asset) in [
        (
          "JetBrainsMono",
          "assets/fonts/JetBrains_Mono/JetBrainsMono-VariableFont_wght.ttf",
        ),
        ("Lilex", "assets/fonts/Lilex/Lilex-VariableFont_wght.ttf"),
        ("MaterialIcons", "fonts/MaterialIcons-Regular.otf"),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      }
    });
  }
  testWidgets(
    "successful feedback expires after ten seconds and later saves appear again",
    (tester) async {
      final workspace = LocalWorkSession();
      final journal = workspace;

      addTearDown(workspace.dispose);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpTestApp(
        child: Scaffold(
          appBar: AppBar(
            actions: [LocalWorkSessionActivityView(controller: workspace)],
          ),
        ),
      );

      expect(find.text("Saved"), findsNothing);
      Future<void> save(int id) async {
        final submission = MutationSubmission<int>(
          id: id,
          label: "Save host",
          send: () async => SubmissionResult.confirmed(id),
        );
        journal.track(submission);
        await submission.run();
      }

      await save(1);
      await tester.pumpAndSettle();
      expect(find.text("Saved"), findsOneWidget);

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, "Saved"),
      );
      final context = tester.element(find.widgetWithText(TextButton, "Saved"));
      expect(
        button.style!.foregroundColor!.resolve({}),
        context.colors.success,
      );

      await tester.tap(find.text("Saved"));
      await tester.pumpAndSettle();
      expect(find.text("Save activity"), findsOneWidget);
      await tester.pump();
      expect(journal.submissions, hasLength(1));
      await tester.pump(savedFeedbackDuration);

      await tester.pumpAndSettle();
      expect(journal.submissions, isEmpty);
      expect(find.text("Saved"), findsNothing);
      expect(find.text("All saved"), findsNothing);
      expect(find.text("No pending changes"), findsOneWidget);

      await tester.tap(find.byTooltip("Close"));
      await tester.pumpAndSettle();
      expect(find.text("Save activity"), findsNothing);
      expect(tester.takeException(), isNull);

      await save(2);
      await tester.pumpAndSettle();
      expect(find.text("Saved"), findsOneWidget);
      await tester.pump(savedFeedbackDuration);
      await tester.pumpAndSettle();
    },
  );

  for (final mobile in [false, true]) {
    testWidgets(
      "activity uses ${mobile ? "a padded mobile sheet" : "an anchored desktop popup"}",
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(mobile ? 390 : 1280, 800);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.binding.setSurfaceSize(Size(mobile ? 390 : 1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final workspace = LocalWorkSession();
        final journal = workspace;

        addTearDown(workspace.dispose);
        final submission = MutationSubmission<void>(
          id: "failed",
          label: "Gabbers Little Corner: configuration",
          send: () async => const SubmissionResult.rejected(
            message: "Choose a supported engine target",
          ),
        );
        journal.track(submission);
        await submission.run();
        await tester.pumpTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [LocalWorkSessionActivityView(controller: workspace)],
            ),
          ),
        );
        if (mobile) {
          await tester.tap(find.byTooltip("Needs attention"));
        } else {
          await tester.tap(find.text("Needs attention"));
        }

        await tester.pumpAndSettle();
        expect(find.text("Save activity"), findsOneWidget);
        expect(
          find.byType(BottomSheet),
          mobile ? findsOneWidget : findsNothing,
        );
        expect(
          find.text("Gabbers Little Corner: configuration"),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (!mobile) {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(find.byTooltip("Close")));
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(tester.takeException(), isNull);

          await mouse.removePointer();
          await tester.pumpAndSettle();
        }

        if (screenshotDirectory.isNotEmpty) {
          await tester.captureScreenshot(
            mobile ? "save-activity-mobile" : "save-activity-desktop",
            directory: screenshotDirectory,
          );
        }
        if (mobile) {
          expect(
            tester.getTopLeft(find.text("Save activity")).dx,
            greaterThan(16),
          );
          await tester.tap(find.byTooltip("Close"));
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pumpAndSettle();
        expect(find.text("Save activity"), findsNothing);
        await tester.pump(const Duration(seconds: 20));
        expect(journal.submissions, hasLength(1));
      },
    );
  }

  testWidgets(
    "attention outranks drafts and stays visible while other work saves",
    (tester) async {
      const failed = LocalWorkSubmissionState(
        id: 1,
        label: "Failed",
        sending: false,
        canReplay: false,
        integrationFailed: false,
        result: LocalWorkSubmissionResult.rejected,
        message: "Rejected",
      );
      const saving = LocalWorkSubmissionState(
        id: 2,
        label: "Saving",
        sending: true,
        canReplay: false,
        integrationFailed: false,
        result: LocalWorkSubmissionResult.ready,
      );
      expect(
        MutationActivityPhase.resolve([failed, saving], const []),
        MutationActivityPhase.savingWithAttention,
      );
      const completed = LocalWorkSubmissionState(
        id: 2,
        label: "Saving",
        sending: false,
        canReplay: false,
        integrationFailed: false,
        result: LocalWorkSubmissionResult.confirmed,
      );
      expect(
        MutationActivityPhase.resolve([failed, completed], const []),
        MutationActivityPhase.needsAttention,
      );
    },
  );

  testWidgets(
    "already confirmed submissions expire but uncertain outcomes do not",
    (tester) async {
      final journal = LocalWorkSession();

      final confirmed = MutationSubmission<void>(
        id: 1,
        label: "Saved",
        send: () async => const SubmissionResult.confirmed(null),
      );
      final uncertain = MutationSubmission<void>(
        id: 2,
        label: "Unknown",
        send: () async => throw StateError("Lost reply"),
      );
      addTearDown(journal.dispose);
      await confirmed.run();
      await uncertain.run();
      journal
        ..track(confirmed)
        ..track(uncertain);

      await tester.pump(savedFeedbackDuration);
      expect(journal.submissions, [uncertain]);
      journal.dismiss(uncertain.id);
      expect(journal.submissions, [uncertain]);
    },
  );
}
