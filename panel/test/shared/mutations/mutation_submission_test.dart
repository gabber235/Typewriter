import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("retrying a failed local refresh of a request that was not submitted "
      "never sends it again", () async {
    var sends = 0;
    var integrations = 0;
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);
    final submission = MutationSubmission<void>(
      id: "known",
      label: "Apply",
      send: () async {
        sends++;
        return const SubmissionNotSubmitted(message: "Connection unavailable");
      },
      integrate: (_) async {
        if (++integrations == 1) throw StateError("Refresh failed");
      },
    );
    addTearDown(submission.dispose);
    await submission.run();
    expect(submission.integrationError?.error, isA<StateError>());
    await submission.run();
    expect(sends, 1);
    expect(integrations, 2);
    expect(submission.integrationError, isNull);
    expect(reported, hasLength(1));
  });
  test(
    "uncertain replay retains the submitted value after a newer edit",
    () async {
      var draft = "A";
      final captured = draft;
      final sent = <String>[];
      final submission = MutationSubmission<String>(
        id: "17",
        label: "Save name",
        replay: SubmissionReplay.identicalRequest,
        send: () async {
          sent.add(captured);
          if (sent.length == 1) throw TimeoutException("Reply lost");
          return SubmissionResult.confirmed(captured);
        },
      );
      addTearDown(submission.dispose);

      expect(await submission.run(), isA<SubmissionUncertain<String>>());
      draft = "B";
      expect(submission.canReplay, isTrue);
      expect(await submission.run(), const SubmissionResult.confirmed("A"));
      expect(sent, ["A", "A"]);
      expect(draft, "B");

      expect(submission.canReplay, isFalse);
    },
  );

  test(
    "unsupported replay never dispatches an uncertain operation twice",
    () async {
      var calls = 0;
      final submission = MutationSubmission<void>(
        id: "generate",
        label: "Generate join code",
        send: () async {
          calls++;
          throw TimeoutException("Reply lost");
        },
      );
      addTearDown(submission.dispose);
      await submission.run();
      expect(submission.canReplay, isFalse);
      await submission.run();

      expect(calls, 1);
    },
  );

  test("an attempt nothing received after an unanswered one leaves the "
      "outcome unknown, since the first may have landed", () async {
    final save = ScriptedSave([
      TimeoutException("Reply lost"),
      const SubmissionResult<String>.undelivered(message: "Away"),
    ]);

    await save.submission.run();
    expect(await save.submission.run(), isA<SubmissionUncertain<String>>());
  });

  test("an unanswered request is sent again on its own, pausing longer each "
      "time, until it is answered", () async {
    final scheduler = ControlledScheduler();
    final save = ScriptedSave([
      TimeoutException("Reply lost"),
      TimeoutException("Reply lost"),
    ], redelivery: scheduler);

    await save.submission.run();
    expect(save.submission.delivering, isTrue);
    (await scheduler.scheduledAt(0)).execute();
    (await scheduler.scheduledAt(1)).execute();
    await pumpEventQueue();

    expect(save.submission.result, const SubmissionResult.confirmed("Saved"));
    expect(save.submission.delivering, isFalse);
    expect(save.sends, 3);
    expect(scheduler.delays, [
      const Duration(milliseconds: 250),
      const Duration(milliseconds: 500),
    ]);
  });

  test("Retry while a resend waits sends at once, and once answered the "
      "request is no longer on its way", () async {
    final scheduler = ControlledScheduler();
    final save = ScriptedSave([
      TimeoutException("Reply lost"),
    ], redelivery: scheduler);

    await save.submission.run();
    final waiting = await scheduler.scheduledAt(0);
    expect(
      await save.submission.run(),
      const SubmissionResult.confirmed("Saved"),
    );
    expect(save.submission.delivering, isFalse);
    waiting.execute();
    await pumpEventQueue();

    expect(save.sends, 2);
  });

  test("disposing a submission stops its waiting resend, and it is never "
      "sent again", () async {
    final scheduler = ControlledScheduler();
    final save = ScriptedSave([
      TimeoutException("Reply lost"),
    ], redelivery: scheduler);

    await save.submission.run();
    final waiting = await scheduler.scheduledAt(0);
    save.submission.dispose();
    expect(waiting.cancelled, isTrue);
    waiting.execute();
    await pumpEventQueue();

    expect(save.sends, 1);
  });

  test("a new attempt replaces only the same resource rejection", () async {
    final journal = testWorkSession();
    MutationSubmission<int> attempt(String id, String scope) =>
        MutationSubmission<int>(
          id: id,
          label: "Edit",
          resources: {(scope, "resource")},
          send: () async =>
              const SubmissionResult.rejected(message: "Rejected"),
        );
    final first = attempt("first", "org1");
    final other = attempt("other", "org2");
    journal
      ..track(first)
      ..track(other);

    await first.run();
    await other.run();
    final replacement = attempt("replacement", "org1");
    journal.track(replacement);
    expect(journal.submissions.map((submission) => submission.id), [
      "other",
      "replacement",
    ]);
  });

  test("concurrent attempts share one request and retain rejection", () async {
    final response = Completer<SubmissionResult<int>>();
    var calls = 0;
    final submission = MutationSubmission<int>(
      id: "roles",
      label: "Apply roles",
      send: () {
        calls++;
        return response.future;
      },
    );
    addTearDown(submission.dispose);
    final first = submission.run();
    final second = submission.run();

    expect(identical(first, second), isTrue);
    response.complete(const SubmissionResult.rejected(message: "Role denied"));
    expect(await first, isA<SubmissionRejected<int>>());
    expect(submission.canReplay, isFalse);
    expect(calls, 1);
  });
}
