import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("queued capture waits for confirmed state integration", () async {
    final work = LocalWorkSession();
    addTearDown(work.dispose);
    final integrated = Completer<void>();
    var revision = 0;
    final first = work.start(
      PreparedCommit<int>(
        id: "first",
        label: "First",
        resources: {"resource"},
        send: () async => const SubmissionResult.confirmed(1),
        integrate: (_) async {
          await integrated.future;
          revision = 1;
        },
      ),
    );
    var prepared = false;

    final queued = work.enqueue(
      PendingCommit(
        resources: {"resource"},
        prepare: () {
          prepared = true;
          final capturedRevision = revision;
          return PreparedCommit<int>(
            id: "second",
            label: "Second",
            resources: {"resource"},
            send: () async => SubmissionResult.confirmed(capturedRevision),
          );
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(prepared, isFalse);
    integrated.complete();
    await first.run();
    final second = await queued;

    expect(await second.run(), const SubmissionResult<int>.confirmed(1));
  });

  test(
    "integration failure preserves acceptance and retries only integration",
    () async {
      final work = LocalWorkSession();
      addTearDown(work.dispose);
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = previousHandler);
      var sends = 0;

      var integrations = 0;
      final integrated = Completer<void>();
      final submission = work.start(
        PreparedCommit<int>(
          id: "operation",
          label: "Save",
          resources: {"resource"},
          send: () async {
            sends++;
            return const SubmissionResult.confirmed(42);
          },
          integrate: (_) async {
            integrations++;
            if (integrations == 1) throw StateError("Refresh failed");
            await integrated.future;
          },
        ),
      );
      expect(await submission.run(), const SubmissionResult<int>.confirmed(42));
      expect(submission.integrationError, isNotNull);
      expect(submission.canReplay, isFalse);

      final refresh = submission.run();
      expect(identical(refresh, submission.run()), isTrue);
      integrated.complete();
      expect(await refresh, const SubmissionResult<int>.confirmed(42));
      expect(submission.integrationError, isNull);
      expect(sends, 1);

      expect(integrations, 2);
    },
  );

  test(
    "uncertain work retains its reservation while disjoint work proceeds",
    () async {
      final work = LocalWorkSession();
      addTearDown(work.dispose);
      var attempts = 0;
      final uncertain = work.start(
        PreparedCommit<int>(
          id: "first",
          label: "First",
          resources: {"resource"},
          replay: SubmissionReplay.identicalRequest,
          send: () async {
            attempts++;
            if (attempts == 1) {
              return SubmissionResult.uncertain(
                message: "Lost reply",
                cause: StateError("Disconnected"),
                stackTrace: StackTrace.current,
              );
            }
            return const SubmissionResult.confirmed(1);
          },
        ),
      );
      await uncertain.run();
      final started = Completer<void>();

      final next = work.start(
        PreparedCommit<int>(
          id: "second",
          label: "Second",
          resources: {"resource"},
          send: () async {
            started.complete();
            return const SubmissionResult.confirmed(2);
          },
        ),
      );
      final disjoint = work.start(
        PreparedCommit<int>(
          id: "third",
          label: "Third",
          resources: {"other"},
          send: () async => const SubmissionResult.confirmed(3),
        ),
      );
      expect(await disjoint.run(), const SubmissionResult<int>.confirmed(3));
      expect(started.isCompleted, isFalse);
      await uncertain.run();
      expect(await next.run(), const SubmissionResult<int>.confirmed(2));

      expect(started.isCompleted, isTrue);
      expect(attempts, 2);
    },
  );
}
