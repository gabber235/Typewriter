import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const phone = Size(390, 800);
  const failure = "Choose a supported engine target";

  testWidgets("saved feedback disappears after a while and later saves show "
      "again", (tester) async {
    final work = testWorkSession();
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));
    expect(panel.shows("Saved"), isFalse);

    await work.submit("Save host", SubmissionResult.confirmed(1), id: 1);
    await panel.settle();
    await panel.activity.open("Saved");
    expect(panel.shows("Save host"), isTrue);

    await tester.pump(savedFeedbackDuration);
    await panel.settle();
    expect(panel.shows("Save host"), isFalse);
    expect(panel.shows("No pending changes"), isTrue);
    expect(panel.shows("Saved"), isFalse);

    await panel.activity.close();
    expect(panel.activity.isOpen, isFalse);
    await work.submit("Save host", SubmissionResult.confirmed(2), id: 2);
    await panel.settle();
    expect(panel.shows("Saved"), isTrue);
    await tester.pump(savedFeedbackDuration);
    await panel.settle();
  });

  testWidgets("the desktop activity opens from the keyboard and Escape closes "
      "it", (tester) async {
    final work = testWorkSession();
    await work.submit<void>(
      "Host configuration",
      const SubmissionResult.rejected(message: failure),
      id: "failed",
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));

    await panel.press(LogicalKeyboardKey.tab);
    expect(panel.focused, "Needs attention");
    await panel.press(LogicalKeyboardKey.enter);
    expect(panel.activity.isOpen, isTrue);
    expect(panel.shows(failure), isTrue);

    await panel.press(LogicalKeyboardKey.escape);
    expect(panel.activity.isOpen, isFalse);
  });

  testWidgets("the mobile activity keeps a margin to the screen edge", (
    tester,
  ) async {
    final work = testWorkSession();
    await work.submit<void>(
      "Host configuration",
      const SubmissionResult.rejected(message: failure),
      id: "failed",
    );
    final panel = await tester.pumpPanel([
      window(phone),
    ], at: saveActivityOf(work));

    await panel.activity.open("Needs attention");

    final heading = tester.getRect(find.text("Save activity"));
    expect(heading.left, greaterThan(16));
    expect(heading.right, lessThan(phone.width - 16));
    expect(panel.shows("Host configuration"), isTrue);
    await panel.activity.close();
    expect(panel.activity.isOpen, isFalse);
  });

  testWidgets("a failed save stays in the activity until it is dismissed", (
    tester,
  ) async {
    final work = testWorkSession();
    await work.submit<void>(
      "Host configuration",
      const SubmissionResult.rejected(message: failure),
      id: "failed",
    );
    final panel = await tester.pumpPanel(const [], at: saveActivityOf(work));

    await tester.pump(const Duration(seconds: 20));
    await panel.activity.open("Needs attention");
    expect(panel.shows(failure), isTrue);

    await panel.tapOn(panel.labeled("Dismiss").first);
    expect(panel.shows(failure), isFalse);
    expect(panel.shows("Needs attention"), isFalse);
  });

  test(
    "attention outranks drafts and stays visible while other work saves",
    () {
      const failed = LocalWorkSubmissionState(
        id: 1,
        label: "Failed",
        phase: LocalWorkSubmissionPhase.settled(
          LocalWorkKnownOutcome.rejected("Rejected"),
          LocalWorkIntegration.applied(),
        ),
      );
      const saving = LocalWorkSubmissionState(
        id: 2,
        label: "Saving",
        phase: LocalWorkSubmissionPhase.active(),
      );
      const completed = LocalWorkSubmissionState(
        id: 2,
        label: "Saving",
        phase: LocalWorkSubmissionPhase.settled(
          LocalWorkKnownOutcome.confirmed(),
          LocalWorkIntegration.applied(),
        ),
      );
      final draft = WorkEntryState(
        id: WorkEntryId(
          driver: const WorkDriverId(domain: "value", scope: "host"),
          identity: const EditGroupId(1),
        ),
        label: "Host",
        phase: "Changes await applying",
        hasWork: true,
        canSave: true,
      );

      expect(
        MutationActivityPhase.resolve([failed, saving], [draft]),
        MutationActivityPhase.savingWithAttention,
      );
      expect(
        MutationActivityPhase.resolve([failed, completed], [draft]),
        MutationActivityPhase.needsAttention,
      );
      expect(
        MutationActivityPhase.resolve([completed], [draft]),
        MutationActivityPhase.drafts,
        reason: "without attention the draft decides",
      );
    },
  );

  testWidgets(
    "already confirmed submissions expire but uncertain outcomes do not",
    (tester) async {
      final journal = testWorkSession();

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
