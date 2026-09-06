// ignore_for_file: cascade_invocations

import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final title = DataPath.root.field("title");
  final color = DataPath.root.field("color");

  test("timer scheduler cancellation settles without executing", () async {
    final task = const TimerEditorDelayScheduler().schedule(
      const Duration(milliseconds: 250),
    );

    task.cancel();

    expect(await task.completed, EditorTaskCompletion.cancelled);
  });

  test("draft changes persist only when flushed", () async {
    final commits = <EditorCommit>[];
    final source = _source(
      commit: (commit) async {
        commits.add(commit);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    source.update(title, const StringValue("New"));
    expect(commits, isEmpty);
    expect(source.saveState(title).phase, EditorSavePhase.pending);
    expect(source.saveState(DataPath.root).phase, EditorSavePhase.pending);
    expect(source.saveState(DataPath.root).path, title);

    await source.flush();
    expect(commits.single.changedPaths, {title});
    expect(
      commits.single.mutations.single,
      isA<EditorSetValue>()
          .having((mutation) => mutation.path, "path", title)
          .having(
            (mutation) => mutation.value,
            "value",
            const StringValue("New"),
          ),
    );
    expect(source.document.revision, 2);
    expect(source.saveState(title).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test("commit groups flush through independent commits", () async {
    final commits = <EditorCommit>[];
    final source = _source(
      commitGroups: {
        DataPath.root.field("title"): "content",
        DataPath.root.field("color"): "appearance",
      },
      commit: (commit) async {
        commits.add(commit);
        return TypedMutationResult.success(
          revision: commit.expectedRevision + 1,
          value: commit.rootValue,
        );
      },
    );

    source
      ..update(title, const StringValue("New"))
      ..update(color, const StringValue("Blue"));
    await source.flush();

    expect(commits, hasLength(2));
    expect(commits.map((commit) => commit.group), ["appearance", "content"]);
    expect(commits[0].changedPaths, {color});
    expect(commits[1].changedPaths, {title});
    expect(
      source.value(DataPath.root).valueOrNull,
      _value(title: "New", color: "Blue"),
    );
    source.dispose();
  });

  test("successful session commits retain session durability", () async {
    final source = _source(
      successfulSavePhase: EditorSavePhase.sessionOnly,
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );

    source.update(title, const StringValue("Session"));
    await source.flush();

    expect(source.saveState(title).phase, EditorSavePhase.sessionOnly);
    source.dispose();
  });

  test(
    "different remote fields rebase and retry with injected jitter",
    () async {
      final scheduler = _Scheduler();
      final sent = <EditorCommit>[];
      var calls = 0;
      final source = _source(
        scheduler: scheduler,
        jitter: const _Jitter(Duration(milliseconds: 10)),
        commit: (commit) async {
          sent.add(commit);
          if (calls++ == 0) {
            return TypedMutationResult.conflict(
              expectedRevision: commit.expectedRevision,
              actualRevision: 2,
              actualValue: _value(title: "Old", color: "Blue"),
            );
          }
          return TypedMutationResult.success(
            revision: 3,
            value: commit.rootValue,
          );
        },
      );

      source.update(title, const StringValue("New"));
      await source.flush();

      expect(scheduler.delays, const [
        Duration(milliseconds: 250),
        Duration(milliseconds: 60),
      ]);
      expect(sent.last.rootValue, _value(title: "New", color: "Blue"));
      expect(source.document.revision, 3);
      source.dispose();
    },
  );

  test("same field changes pause with an inline conflict", () async {
    var calls = 0;
    final source = _source(
      commit: (commit) async {
        calls++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: _value(title: "Theirs", color: "Red"),
        );
      },
    );

    source.update(title, const StringValue("Yours"));
    await source.flush();

    expect(calls, 1);
    expect(source.value(title).valueOrNull, const StringValue("Yours"));
    expect(source.saveState(title).phase, EditorSavePhase.conflict);

    source.useRemote(title);
    expect(source.value(title).valueOrNull, const StringValue("Theirs"));
    source.dispose();
  });

  test("conflicting paths do not pause clean rebased paths", () async {
    final commits = <EditorCommit>[];
    final source = _source(
      scheduler: _Scheduler(),
      jitter: const _Jitter(Duration.zero),
      commit: (commit) async {
        commits.add(commit);
        if (commits.length == 1) {
          return TypedMutationResult.conflict(
            expectedRevision: commit.expectedRevision,
            actualRevision: 2,
            actualValue: _value(title: "Theirs", color: "Red"),
          );
        }
        return TypedMutationResult.success(
          revision: 3,
          value: commit.rootValue,
        );
      },
    );

    source.update(title, const StringValue("Yours"));
    source.update(color, const StringValue("Blue"));
    await source.flush();

    expect(commits, hasLength(2));
    expect(commits.last.changedPaths, {color});
    expect(commits.last.rootValue, _value(title: "Theirs", color: "Blue"));
    expect(source.value(title).valueOrNull, const StringValue("Yours"));
    expect(source.saveState(title).phase, EditorSavePhase.conflict);
    expect(source.saveState(color).phase, EditorSavePhase.saved);
    expect(
      source.document.confirmedValue,
      _value(title: "Theirs", color: "Blue"),
    );
    source.dispose();
  });

  test(
    "stale in flight success retries without regressing remote state",
    () async {
      final first = Completer<TypedMutationResult>();
      final commits = <EditorCommit>[];
      final source = _source(
        scheduler: _Scheduler(),
        jitter: const _Jitter(Duration.zero),
        commit: (commit) async {
          commits.add(commit);
          if (commits.length == 1) return first.future;
          return TypedMutationResult.success(
            revision: 4,
            value: commit.rootValue,
          );
        },
      );

      source.update(title, const StringValue("New"));
      final flush = source.flush();
      source.acceptRemote(
        revision: 3,
        value: _value(title: "Old", color: "Blue"),
      );
      first.complete(
        TypedMutationResult.success(
          revision: 2,
          value: _value(title: "New", color: "Red"),
        ),
      );
      await flush;

      expect(commits, hasLength(2));
      expect(commits.last.expectedRevision, 3);
      expect(commits.last.rootValue, _value(title: "New", color: "Blue"));
      expect(source.document.revision, 4);
      expect(
        source.document.confirmedValue,
        _value(title: "New", color: "Blue"),
      );
      source.dispose();
    },
  );

  test("same revision matching success confirms the pending commit", () async {
    final pending = Completer<TypedMutationResult>();
    final source = _source(commit: (_) => pending.future);

    source.update(title, const StringValue("New"));
    final flush = source.flush();
    source.acceptRemote(
      revision: 2,
      value: _value(title: "New", color: "Red"),
    );
    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: _value(title: "New", color: "Red"),
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
      final source = _source(commit: (_) => pending.future);

      source.update(title, const StringValue("New"));
      final flush = source.flush();
      source.acceptRemote(
        revision: 2,
        value: _value(title: "Old", color: "Blue"),
      );
      pending.complete(
        TypedMutationResult.success(
          revision: 2,
          value: _value(title: "New", color: "Red"),
        ),
      );
      await flush;

      expect(source.document.revision, 2);
      expect(
        source.document.confirmedValue,
        _value(title: "Old", color: "Blue"),
      );
      expect(source.value(title).valueOrNull, const StringValue("New"));
      expect(
        source.document.diagnostics.map((diagnostic) => diagnostic.message),
        contains("Different values share the same revision"),
      );
      expect(source.saveState(title).phase, EditorSavePhase.failed);
      source.dispose();
    },
  );

  test("a focused field does not block other fields from saving", () async {
    final scheduler = _ControlledScheduler();
    final committed = Completer<void>();
    final commits = <EditorCommit>[];
    final source = _source(
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
    source.update(title, const StringValue("Typing"));
    source.update(color, const StringValue("Blue"));
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
    final source = _source(
      commit: (commit) async => fail
          ? TypedMutationResult.unavailable([
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidValue,
                message: "Rejected",
              ),
            ])
          : TypedMutationResult.success(
              revision: commit.expectedRevision + 1,
              value: commit.rootValue,
            ),
    );

    source.update(title, const StringValue("First"));
    await source.flush();
    expect(source.saveState(title).phase, EditorSavePhase.failed);
    expect(source.saveState(DataPath.root).phase, EditorSavePhase.failed);

    fail = false;
    source.update(title, const StringValue("Second"));
    expect(source.saveState(title).phase, EditorSavePhase.pending);

    await source.flush();
    expect(source.saveState(title).phase, EditorSavePhase.saved);
    expect(source.saveState(DataPath.root).phase, EditorSavePhase.saved);
    source.dispose();
  });

  test("failed saves wait for an explicit retry", () async {
    final scheduler = _ControlledScheduler();
    final firstCommit = Completer<void>();
    var calls = 0;
    final source = _source(
      scheduler: scheduler,
      commit: (commit) async {
        calls++;
        if (!firstCommit.isCompleted) firstCommit.complete();
        return TypedMutationResult.unavailable([
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Rejected",
          ),
        ]);
      },
    );

    source.update(title, const StringValue("New"));
    scheduler.tasks.single.execute();
    await firstCommit.future;
    await source.flush(paths: {color});
    expect(calls, 1);
    expect(source.saveState(title).phase, EditorSavePhase.failed);

    await source.flush(paths: {title});
    expect(calls, 2);
    source.dispose();
  });

  test("debounce rescheduling cancels and coalesces pending commits", () async {
    final scheduler = _ControlledScheduler();
    final committed = Completer<void>();
    final commits = <EditorCommit>[];
    final source = _source(
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

    source.update(title, const StringValue("First"));
    final firstTask = scheduler.tasks.single;
    source.update(title, const StringValue("Second"));

    expect(firstTask.cancelled, isTrue);
    expect(scheduler.delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 250),
    ]);

    scheduler.tasks.last.execute();
    await committed.future;
    await source.flush();

    expect(commits, hasLength(1));
    expect(commits.single.rootValue, _value(title: "Second", color: "Red"));
    source.dispose();
  });

  test("deletion cancels debounce and prevents its commit", () async {
    final scheduler = _ControlledScheduler();
    var commits = 0;
    final source = _source(
      scheduler: scheduler,
      commit: (_) async {
        commits++;
        return TypedMutationResult.success(
          revision: 2,
          value: _value(title: "New", color: "Red"),
        );
      },
    );

    source.update(title, const StringValue("New"));
    final task = scheduler.tasks.single;
    source.acceptRemoteDeletion();

    expect(task.cancelled, isTrue);
    expect(await task.completed, EditorTaskCompletion.cancelled);
    expect(commits, 0);
    source.dispose();
  });

  test("dispose cancels debounce and prevents its commit", () async {
    final scheduler = _ControlledScheduler();
    var commits = 0;
    final source = _source(
      scheduler: scheduler,
      commit: (_) async {
        commits++;
        return TypedMutationResult.success(
          revision: 2,
          value: _value(title: "New", color: "Red"),
        );
      },
    );

    source.update(title, const StringValue("New"));
    final task = scheduler.tasks.single;
    source.dispose();

    expect(task.cancelled, isTrue);
    expect(await task.completed, EditorTaskCompletion.cancelled);
    expect(commits, 0);
  });

  test("deletion cancels a retry without another commit", () async {
    final scheduler = _ControlledScheduler();
    var calls = 0;
    final source = _source(
      scheduler: scheduler,
      jitter: const _Jitter(Duration.zero),
      commit: (commit) async {
        calls++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: 2,
          actualValue: _value(title: "Old", color: "Blue"),
        );
      },
    );

    source.update(title, const StringValue("New"));
    final flush = source.flush();
    final retry = await scheduler.scheduledAt(1);
    source.acceptRemoteDeletion();

    expect(retry.cancelled, isTrue);
    expect(await flush, isA<MutationConflict>());
    expect(calls, 1);
    source.dispose();
  });

  test("a committed interaction cannot be reused", () async {
    final source = _source(
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );

    final interaction = source.beginInteraction(title);
    source.update(title, const StringValue("New"));
    await interaction.commit();
    expect(interaction.active, isFalse);
    expect(await interaction.commit(), isA<MutationUnavailable>());
    source.dispose();
  });

  test(
    "interaction cancel restores its origin and commit flushes once",
    () async {
      var calls = 0;
      final source = _source(
        commit: (commit) async {
          calls++;
          return TypedMutationResult.success(
            revision: commit.expectedRevision + 1,
            value: commit.rootValue,
          );
        },
      );
      final cancelled = source.beginInteraction(title);
      source.update(title, const StringValue("Cancelled"));
      cancelled.cancel();
      expect(source.value(title).valueOrNull, const StringValue("Old"));
      expect(calls, 0);

      final committed = source.beginInteraction(title);
      source.update(title, const StringValue("Saved"));
      await committed.commit();
      expect(calls, 1);
      source.dispose();
    },
  );

  test("repeated contention pauses after three jittered retries", () async {
    final scheduler = _Scheduler();
    var revision = 1;
    final source = _source(
      scheduler: scheduler,
      jitter: const _Jitter(Duration.zero),
      commit: (commit) async {
        revision++;
        return TypedMutationResult.conflict(
          expectedRevision: commit.expectedRevision,
          actualRevision: revision,
          actualValue: _value(title: "Old", color: "Remote $revision"),
        );
      },
    );

    source.update(title, const StringValue("New"));
    await source.flush();

    expect(scheduler.delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 50),
      Duration(milliseconds: 100),
      Duration(milliseconds: 200),
    ]);
    expect(source.saveState(title).phase, EditorSavePhase.repeatedContention);
    source.dispose();
  });

  test("deletion invalidates pending request results", () async {
    final pending = Completer<TypedMutationResult>();
    var deleted = false;
    final source = _source(
      commit: (_) => pending.future,
      onDeleted: () => deleted = true,
    );
    source.update(title, const StringValue("New"));
    final flush = source.flush();
    source.acceptRemoteDeletion();
    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: _value(title: "New", color: "Red"),
      ),
    );

    expect(await flush, isA<MutationUnavailable>());
    await Future<void>.delayed(Duration.zero);
    expect(deleted, isTrue);
    source.dispose();
  });

  test("dispose invalidates an in flight commit completion", () async {
    final pending = Completer<TypedMutationResult>();
    var commits = 0;
    var notifications = 0;
    final source = _source(
      commit: (_) {
        commits++;
        return pending.future;
      },
    )..addListener(() => notifications++);
    source.update(title, const StringValue("New"));
    final flush = source.flush();
    final notificationsAtDispose = notifications;

    source.dispose();
    pending.complete(
      TypedMutationResult.success(
        revision: 2,
        value: _value(title: "New", color: "Red"),
      ),
    );

    expect(await flush, isA<MutationUnavailable>());
    expect(commits, 1);
    expect(notifications, notificationsAtDispose);
    expect(source.document.revision, 1);
    expect(source.document.confirmedValue, _value(title: "Old", color: "Red"));
  });

  test("clean remote deletion remains visible at the root", () {
    final source = _source(
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );

    source.acceptRemoteDeletion();

    expect(
      source.saveState(DataPath.root).phase,
      EditorSavePhase.deletedElsewhere,
    );
    source.dispose();
  });

  test("metadata refresh preserves a rebased local draft", () {
    final collection = LocalPresentationCollectionSource(
      id: const PresentationCollectionSourceId("metadata"),
      schema: const PresentationCollectionSchema(
        rowType: StringType(),
        keyType: StringType(),
        rowBindingId: BindingId(3),
        key: TypedExpression(
          resultType: StringType(),
          expression: BindingExpression(
            BindingReference(bindingId: BindingId(3)),
          ),
        ),
      ),
      rows: const [StringValue("row")],
      registry: TypeRegistry(const TypeCatalog([])),
    );
    final source = _source(
      commit: (commit) async => TypedMutationResult.success(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    );
    var notifications = 0;
    source.addListener(() => notifications++);
    source.update(title, const StringValue("Local"));
    final notificationsBeforeRefresh = notifications;

    final refreshed = EditorDocument(
      rootType: source.document.rootType,
      typeCatalog: const TypeCatalog([]),
      confirmedValue: _value(title: "Old", color: "Remote"),
      revision: 2,
      collections: [collection],
      readOnly: true,
    );
    source.refreshDocument(refreshed);

    expect(source.value(title).valueOrNull, const StringValue("Local"));
    expect(
      source.value(DataPath.root.field("color")).valueOrNull,
      const StringValue("Remote"),
    );
    expect(source.document.collections, [collection]);
    expect(source.document.readOnly, isTrue);
    expect(notifications, greaterThan(notificationsBeforeRefresh));

    final notificationsAfterRefresh = notifications;
    source.refreshDocument(refreshed);
    expect(notifications, notificationsAfterRefresh);
    source.dispose();
  });
}

TransactionalEditorSource _source({
  required EditorCommitter commit,
  Map<DataPath, String> commitGroups = const {},
  EditorDelayScheduler? scheduler,
  EditorJitterSource? jitter,
  EditorSavePhase successfulSavePhase = EditorSavePhase.saved,
  Duration debounce = const Duration(milliseconds: 250),
  void Function()? onDeleted,
}) {
  return TransactionalEditorSource(
    document: EditorDocument(
      rootType: RecordType(
        fields: const {
          "title": TypeField(name: "title", type: StringType()),
          "color": TypeField(name: "color", type: StringType()),
        },
      ),
      typeCatalog: const TypeCatalog([]),
      confirmedValue: _value(title: "Old", color: "Red"),
      revision: 1,
      commitGroups: commitGroups,
    ),
    debounce: debounce,
    commit: commit,
    scheduler: scheduler ?? _ControlledScheduler(),
    jitter: jitter,
    successfulSavePhase: successfulSavePhase,
    onDeleted: onDeleted,
  );
}

RecordValue _value({required String title, required String color}) =>
    RecordValue({"title": StringValue(title), "color": StringValue(color)});

final class _Scheduler implements EditorDelayScheduler {
  final delays = <Duration>[];

  @override
  EditorScheduledTask schedule(Duration delay) {
    delays.add(delay);
    if (delay == const Duration(milliseconds: 250)) {
      return _ControlledScheduledTask();
    }
    return const _CompletedScheduledTask();
  }
}

final class _CompletedScheduledTask implements EditorScheduledTask {
  const _CompletedScheduledTask();

  @override
  Future<EditorTaskCompletion> get completed =>
      Future<EditorTaskCompletion>.value(EditorTaskCompletion.executed);

  @override
  void cancel() {}
}

final class _ControlledScheduler implements EditorDelayScheduler {
  final delays = <Duration>[];
  final tasks = <_ControlledScheduledTask>[];
  final _waiters = <int, Completer<_ControlledScheduledTask>>{};

  @override
  EditorScheduledTask schedule(Duration delay) {
    delays.add(delay);
    final task = _ControlledScheduledTask();
    tasks.add(task);
    _waiters.remove(tasks.length - 1)?.complete(task);
    return task;
  }

  Future<_ControlledScheduledTask> scheduledAt(int index) {
    if (tasks.length > index) return Future.value(tasks[index]);
    return _waiters
        .putIfAbsent(index, Completer<_ControlledScheduledTask>.new)
        .future;
  }
}

final class _ControlledScheduledTask implements EditorScheduledTask {
  final Completer<EditorTaskCompletion> _completion =
      Completer<EditorTaskCompletion>();
  bool cancelled = false;

  @override
  Future<EditorTaskCompletion> get completed => _completion.future;

  void execute() {
    if (_completion.isCompleted) return;
    _completion.complete(EditorTaskCompletion.executed);
  }

  @override
  void cancel() {
    if (_completion.isCompleted) return;
    cancelled = true;
    _completion.complete(EditorTaskCompletion.cancelled);
  }
}

final class _Jitter implements EditorJitterSource {
  const _Jitter(this.value);

  final Duration value;

  @override
  Duration next(Duration maximum) {
    assert(value <= maximum, "Test jitter must not exceed its maximum.");
    return value;
  }
}
