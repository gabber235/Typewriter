// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final title = editorRootPath.field("title");
  final color = editorRootPath.field("color");

  test("timer scheduler cancellation settles without executing", () async {
    final task = const TimerEditorDelayScheduler().schedule(
      const Duration(milliseconds: 250),
    );

    task.cancel();

    expect(await task.completed, EditorTaskCompletion.cancelled);
  });

  test("draft changes persist only when flushed", () async {
    final commits = <EditorCommit>[];
    final source = titleAndColorSource(
      commit: (commit) async {
        commits.add(commit);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("New"));
    expect(commits, isEmpty);
    expect(source.saveState(title).phase, EditorSavePhase.pending);
    expect(source.saveState(editorRootPath).phase, EditorSavePhase.pending);
    expect(source.saveState(editorRootPath).path, title);

    await source.flush();
    expect(commits.single.changedPaths, {title});
    expect(
      commits.single.mutations.single,
      isA<EditorSetValue>()
          .having((mutation) => mutation.path, "path", title)
          .having(
            (mutation) => mutation.value,
            "value",
            skir.DataValue.wrapStringValue("New"),
          ),
    );
    expect(source.document.revision, 2);
    expect(source.saveState(title).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test(
    "different remote fields rebase and retry with injected jitter",
    () async {
      final scheduler = RecordingScheduler();
      final sent = <EditorCommit>[];
      var calls = 0;
      final source = titleAndColorSource(
        scheduler: scheduler,
        jitter: const FixedJitter(Duration(milliseconds: 10)),
        commit: (commit) async {
          sent.add(commit);
          if (calls++ == 0) {
            return TypedMutationResult.conflict(
              expectedRevision: commit.expectedRevision,
              actualRevision: 2,
              actualValue: titleAndColorValue(title: "Old", color: "Blue"),
            );
          }
          return TypedMutationResult.success(
            revision: 3,
            value: commit.rootValue,
          );
        },
      );

      source.update(title, skir.DataValue.wrapStringValue("New"));
      await source.flush();

      expect(scheduler.delays, const [
        Duration(milliseconds: 250),
        Duration(milliseconds: 60),
      ]);
      expect(
        sent.last.rootValue,
        titleAndColorValue(title: "New", color: "Blue"),
      );
      expect(source.document.revision, 3);
      source.dispose();
    },
  );

  test("same field changes pause with an inline conflict", () async {
    var calls = 0;
    final source = titleAndColorSource(
      commit: (commit) async {
        calls++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: titleAndColorValue(title: "Theirs", color: "Red"),
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("Yours"));
    await source.flush();

    expect(calls, 1);
    expect(
      source.value(title).valueOrNull,
      skir.DataValue.wrapStringValue("Yours"),
    );
    expect(source.saveState(title).phase, EditorSavePhase.conflict);

    source.useRemote(title);
    expect(
      source.value(title).valueOrNull,
      skir.DataValue.wrapStringValue("Theirs"),
    );
    source.dispose();
  });

  test("conflicting paths do not pause clean rebased paths", () async {
    final commits = <EditorCommit>[];
    final source = titleAndColorSource(
      scheduler: RecordingScheduler(),
      jitter: const FixedJitter(Duration.zero),
      commit: (commit) async {
        commits.add(commit);
        if (commits.length == 1) {
          return TypedMutationResult.conflict(
            expectedRevision: commit.expectedRevision,
            actualRevision: 2,
            actualValue: titleAndColorValue(title: "Theirs", color: "Red"),
          );
        }
        return TypedMutationResult.success(
          revision: 3,
          value: commit.rootValue,
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("Yours"));
    source.update(color, skir.DataValue.wrapStringValue("Blue"));
    await source.flush();

    expect(commits, hasLength(2));
    expect(commits.last.changedPaths, {color});
    expect(
      commits.last.rootValue,
      titleAndColorValue(title: "Theirs", color: "Blue"),
    );
    expect(
      source.value(title).valueOrNull,
      skir.DataValue.wrapStringValue("Yours"),
    );
    expect(source.saveState(title).phase, EditorSavePhase.conflict);
    expect(source.saveState(color).phase, EditorSavePhase.saved);

    expect(
      source.document.confirmedValue,
      titleAndColorValue(title: "Theirs", color: "Blue"),
    );
    source.dispose();
  });

  test(
    "stale accepted result acknowledges captured edits without resending",
    () async {
      final first = Completer<TypedMutationResult>();
      final commits = <EditorCommit>[];
      final source = titleAndColorSource(
        scheduler: RecordingScheduler(),
        jitter: const FixedJitter(Duration.zero),
        commit: (commit) async {
          commits.add(commit);
          if (commits.length == 1) return first.future;
          return TypedMutationResult.success(
            revision: 4,
            value: commit.rootValue,
          );
        },
      );

      source.update(title, skir.DataValue.wrapStringValue("New"));
      final flush = source.flush();
      source.acceptRemote(
        revision: 3,
        value: titleAndColorValue(title: "Old", color: "Blue"),
      );
      first.complete(
        TypedMutationResult.success(
          revision: 2,
          value: titleAndColorValue(title: "New", color: "Red"),
        ),
      );
      await flush;

      expect(commits, hasLength(1));
      expect(source.document.revision, 3);
      expect(
        source.document.confirmedValue,
        titleAndColorValue(title: "Old", color: "Blue"),
      );
      expect(
        source.value(editorRootPath).valueOrNull,
        titleAndColorValue(title: "Old", color: "Blue"),
      );
      expect(source.saveState(title).phase, EditorSavePhase.saved);
      source.dispose();
    },
  );

  test("same revision matching success confirms the pending commit", () async {
    final pending = Completer<TypedMutationResult>();
    final source = titleAndColorSource(commit: (_) => pending.future);

    source.update(title, skir.DataValue.wrapStringValue("New"));
    final flush = source.flush();
    source.acceptRemote(
      revision: 2,
      value: titleAndColorValue(title: "New", color: "Red"),
    );
    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: titleAndColorValue(title: "New", color: "Red"),
      ),
    );
    await flush;

    expect(source.document.revision, 2);
    expect(source.saveState(title).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test(
    "same revision divergent success is diagnosed without overwrite",
    () async {
      final pending = Completer<TypedMutationResult>();
      final source = titleAndColorSource(commit: (_) => pending.future);

      source.update(title, skir.DataValue.wrapStringValue("New"));
      final flush = source.flush();
      source.acceptRemote(
        revision: 2,
        value: titleAndColorValue(title: "Old", color: "Blue"),
      );
      pending.complete(
        TypedMutationResult.success(
          revision: 2,
          value: titleAndColorValue(title: "New", color: "Red"),
        ),
      );
      await flush;

      expect(source.document.revision, 2);
      expect(
        source.document.confirmedValue,
        titleAndColorValue(title: "Old", color: "Blue"),
      );
      expect(
        source.value(title).valueOrNull,
        skir.DataValue.wrapStringValue("New"),
      );
      expect(
        source.document.diagnostics.map((diagnostic) => diagnostic.message),
        contains("Different values share the same revision"),
      );
      expect(source.saveState(title).phase, EditorSavePhase.failed);
      source.dispose();
    },
  );

  test("a focused field does not block other fields from saving", () async {
    final scheduler = ControlledScheduler();
    final committed = Completer<void>();
    final commits = <EditorCommit>[];
    final source = titleAndColorSource(
      scheduler: scheduler,
      commit: (commit) async {
        commits.add(commit);
        if (!committed.isCompleted) committed.complete();
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    source.beginInteraction(title);
    source.update(title, skir.DataValue.wrapStringValue("Typing"));
    source.update(color, skir.DataValue.wrapStringValue("Blue"));
    scheduler.tasks.last.execute();
    await committed.future;
    await source.flush(paths: {color});

    expect(commits.single.changedPaths, {color});
    expect(source.saveState(title).phase, EditorSavePhase.pending);
    expect(source.saveState(color).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test("editing after a failure returns the field to pending", () async {
    var fail = true;
    final source = titleAndColorSource(
      commit: (commit) async => fail
          ? TypedMutationResult.unavailable([
              const EditorDiagnostic(
                code: EditorDiagnosticCode.invalidValue,
                message: "Rejected",
              ),
            ])
          : TypedMutationResult.success(
              revision: commit.expectedRevision + 1,
              value: commit.rootValue,
            ),
    );

    source.update(title, skir.DataValue.wrapStringValue("First"));
    await source.flush();
    expect(source.saveState(title).phase, EditorSavePhase.failed);
    expect(source.saveState(editorRootPath).phase, EditorSavePhase.failed);

    fail = false;
    source.update(title, skir.DataValue.wrapStringValue("Second"));
    expect(source.saveState(title).phase, EditorSavePhase.pending);

    await source.flush();
    expect(source.saveState(title).phase, EditorSavePhase.saved);
    expect(source.saveState(editorRootPath).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test("failed saves wait for an explicit retry", () async {
    final scheduler = ControlledScheduler();
    final firstCommit = Completer<void>();
    var calls = 0;
    final source = titleAndColorSource(
      scheduler: scheduler,
      commit: (commit) async {
        calls++;
        if (!firstCommit.isCompleted) firstCommit.complete();
        return TypedMutationResult.unavailable([
          const EditorDiagnostic(
            code: EditorDiagnosticCode.invalidValue,
            message: "Rejected",
          ),
        ]);
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("New"));
    scheduler.tasks.single.execute();
    await firstCommit.future;
    await pumpEventQueue();
    await source.flush(paths: {color});
    expect(calls, 1);
    expect(source.saveState(title).phase, EditorSavePhase.failed);

    await source.flush(paths: {title});
    expect(calls, 2);
    source.dispose();
  });

  test("debounce rescheduling cancels and coalesces pending commits", () async {
    final scheduler = ControlledScheduler();
    final committed = Completer<void>();
    final commits = <EditorCommit>[];
    final source = titleAndColorSource(
      scheduler: scheduler,
      commit: (commit) async {
        commits.add(commit);
        committed.complete();
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("First"));
    final firstTask = scheduler.tasks.single;
    source.update(title, skir.DataValue.wrapStringValue("Second"));

    expect(firstTask.cancelled, isTrue);
    expect(scheduler.delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
    ]);

    scheduler.tasks.last.execute();
    await committed.future;
    await source.flush();

    expect(commits, hasLength(1));
    expect(
      commits.single.rootValue,
      titleAndColorValue(title: "Second", color: "Red"),
    );
    source.dispose();
  });

  test("deletion cancels debounce and prevents its commit", () async {
    final commits = <EditorCommit>[];
    final (:source, :task) = debouncedTitleEdit(commits);
    source.acceptRemoteDeletion();

    await eventually(() => expect(task.cancelled, isTrue));
    expect(await task.completed, EditorTaskCompletion.cancelled);
    expect(commits.length, 0);
    source.dispose();
  });

  test("dispose cancels debounce and prevents its commit", () async {
    final commits = <EditorCommit>[];
    final (:source, :task) = debouncedTitleEdit(commits);
    source.dispose();

    expect(task.cancelled, isTrue);
    expect(await task.completed, EditorTaskCompletion.cancelled);
    expect(commits.length, 0);
  });

  test("deletion cancels a retry without another commit", () async {
    final scheduler = ControlledScheduler();
    var calls = 0;
    final source = titleAndColorSource(
      scheduler: scheduler,
      jitter: const FixedJitter(Duration.zero),
      commit: (commit) async {
        calls++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: titleAndColorValue(title: "Old", color: "Blue"),
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("New"));
    final flush = source.flush();
    final retry = await scheduler.scheduledAt(1);
    source.acceptRemoteDeletion();

    await eventually(() => expect(retry.cancelled, isTrue));
    expect(await flush, isA<MutationUnavailable>());
    expect(calls, 1);
    source.dispose();
  });

  test("a committed interaction cannot be reused", () async {
    var calls = 0;
    final source = titleAndColorSource(
      commit: (commit) async {
        calls++;
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    final interaction = source.beginInteraction(title);
    source.update(title, skir.DataValue.wrapStringValue("New"));
    await interaction.commit();
    await interaction.commit();
    await source.flush();

    expect(interaction.active, isFalse);
    expect(calls, 1);
    expect(source.hasWork, isFalse);
    source.dispose();
  });

  test(
    "interaction cancel restores its origin and commit flushes once",
    () async {
      var calls = 0;
      final source = titleAndColorSource(
        commit: (commit) async {
          calls++;
          return TypedMutationResult.success(
            revision: commit.expectedRevision + 1,
            value: commit.rootValue,
          );
        },
      );
      final cancelled = source.beginInteraction(title);
      source.update(title, skir.DataValue.wrapStringValue("Cancelled"));
      cancelled.cancel();
      expect(
        source.value(title).valueOrNull,
        skir.DataValue.wrapStringValue("Old"),
      );

      expect(calls, 0);

      final committed = source.beginInteraction(title);
      source.update(title, skir.DataValue.wrapStringValue("Saved"));
      await committed.commit();
      expect(calls, 1);
      source.dispose();
    },
  );

  test("repeated contention pauses after three jittered retries", () async {
    final scheduler = RecordingScheduler();
    var calls = 0;
    var revision = 1;
    final source = titleAndColorSource(
      scheduler: scheduler,
      jitter: const FixedJitter(Duration.zero),
      commit: (commit) async {
        calls++;
        revision++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: revision,
          actualValue: titleAndColorValue(
            title: "Old",
            color: "Remote $revision",
          ),
        );
      },
    );

    source.update(title, skir.DataValue.wrapStringValue("New"));
    await source.flush();

    expect(scheduler.delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 50),
      Duration(milliseconds: 100),
      Duration(milliseconds: 200),
    ]);
    expect(calls, 4);
    expect(
      source.value(title).valueOrNull,
      skir.DataValue.wrapStringValue("New"),
    );
    expect(source.saveState(title).phase, EditorSavePhase.repeatedContention);
    final contention = source.saveState(title).contention!;
    expect(contention.kind, EditorContentionKind.versionMismatch);
    expect(contention.attempts, 4);
    expect(contention.retryLimit, 3);
    expect(contention.expectedVersion, 4);
    expect(contention.observedVersion, 5);
    expect(contention.paths, {title});
    source.dispose();
  });

  test("deletion invalidates pending request results", () async {
    final pending = Completer<TypedMutationResult>();

    final source = titleAndColorSource(commit: (_) => pending.future);
    source.update(title, skir.DataValue.wrapStringValue("New"));
    final flush = source.flush();
    source.acceptRemoteDeletion();

    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: titleAndColorValue(title: "New", color: "Red"),
      ),
    );

    expect(await flush, isA<MutationUnavailable>());
    await Future<void>.delayed(Duration.zero);
    expect(source.readOnly, isTrue);
    source.dispose();
  });

  test("dispose invalidates an in flight commit completion", () async {
    final pending = Completer<TypedMutationResult>();
    var commits = 0;
    var notifications = 0;
    final source = titleAndColorSource(
      commit: (_) {
        commits++;
        return pending.future;
      },
    )..addListener(() => notifications++);
    source.update(title, skir.DataValue.wrapStringValue("New"));
    final flush = source.flush();

    await pumpEventQueue();
    final notificationsAtDispose = notifications;

    source.dispose();
    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: titleAndColorValue(title: "New", color: "Red"),
      ),
    );

    expect(await flush, isA<MutationUnavailable>());
    expect(commits, 1);
    expect(notifications, notificationsAtDispose);
    expect(source.document.revision, 1);
    expect(
      source.document.confirmedValue,
      titleAndColorValue(title: "Old", color: "Red"),
    );
  });

  test("clean remote deletion remains visible at the root", () async {
    final source = titleAndColorSource(
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );

    source.acceptRemoteDeletion();

    await eventually(
      () => expect(
        source.saveState(editorRootPath).phase,
        EditorSavePhase.deletedElsewhere,
      ),
    );
    source.dispose();
  });

  test("metadata refresh preserves a rebased local draft", () async {
    final source = titleAndColorSource(
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );
    var notifications = 0;
    source.addListener(() => notifications++);
    source.update(title, skir.DataValue.wrapStringValue("Local"));
    final notificationsBeforeRefresh = notifications;

    final refreshed = source.document.copyWith(
      confirmedValue: titleAndColorValue(title: "Old", color: "Remote"),
      revision: 2,
      readOnly: true,
    );
    source.refreshDocument(refreshed);

    await eventually(
      () => expect(
        source.value(editorRootPath.field("color")).valueOrNull,
        skir.DataValue.wrapStringValue("Remote"),
      ),
    );
    expect(
      source.value(title).valueOrNull,
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(source.document.readOnly, isTrue);
    expect(notifications, greaterThan(notificationsBeforeRefresh));

    final notificationsAfterRefresh = notifications;
    source.refreshDocument(refreshed);
    expect(notifications, notificationsAfterRefresh);
    source.dispose();
  });
}
