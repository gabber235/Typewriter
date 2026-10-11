import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
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

  test("a new attempt replaces only the same resource rejection", () async {
    final journal = ScopedWorkSession();
    addTearDown(journal.dispose);
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
