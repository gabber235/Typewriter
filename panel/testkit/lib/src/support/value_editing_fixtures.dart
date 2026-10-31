import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The record value holding only [title].
skir.DataValue titleValue(String title) =>
    recordEditorValue({"title": skir.DataValue.wrapStringValue(title)});

/// A single-field title snapshot at [revision], accepting every edit.
EditorSnapshot savedTitleSnapshot({
  String title = "Original",
  int revision = 1,
}) => FakeEditorSnapshot(
  recordEditorDocument(
    {"title": skir.DataValue.wrapStringValue(title)},
    {"title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
    revision,
  ),
  validation: acceptTestEditorMutation,
);

/// A value editing draft over [resource] in [workspace] with its title set to
/// "Draft", holding the resource lease until the test ends.
ValueEditing titleDraft(
  ScopedWorkSession workspace,
  ValueEditPersistence resource,
) {
  final source = ValueEditingRegistration(
    targetId: resource.key.identity,
    label: "Resource",
    persistence: resource,
    snapshot: savedTitleSnapshot(),
    commitPolicy: EditorCommitPolicy.applyResource,
  ).acquire(workspace);
  addTearDown(
    workspace.lease(WorkDriverId(domain: "value", scope: resource.key)).release,
  );
  source.update(
    editorRootPath.field("title"),
    skir.DataValue.wrapStringValue("Draft"),
  );
  return source;
}

/// Captures the errors reported to Flutter while the current test runs.
List<FlutterErrorDetails> captureFlutterErrors() {
  final reports = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = reports.add;
  addTearDown(() => FlutterError.onError = previous);
  return reports;
}

/// A resource whose refresh is counted and whose commit reply is lost: the
/// send is recorded in [sends] and reports an uncertain outcome.
final class UncertainSaveResource extends ScriptedValuePersistence {
  UncertainSaveResource({required super.key, required super.current})
    : super(commit: (_) async => throw StateError("Use captured request"));

  int reads = 0;
  int sends = 0;
  final requests = <EditorCommit>[];

  @override
  Future<EditorSnapshot?> refreshSnapshot() async {
    reads++;
    return current;
  }

  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit changes,
  ) => PreparedCommit(
    id: Object(),
    label: "Uncertain resource",
    resources: reservations,
    replay: SubmissionReplay.identicalRequest,
    send: () async {
      requests.add(changes);
      if (++sends == 1) {
        return SubmissionResult.uncertain(
          message: "Lost response",
          cause: StateError("Lost response"),
          stackTrace: StackTrace.current,
        );
      }
      return SubmissionResult.confirmed(
        MutationSuccess(revision: 2, value: changes.rootValue),
      );
    },
  );
}

/// A configuration resource whose every send reports an uncertain outcome and
/// whose saved values can be read only before the first save, so the outcome
/// stays unknown.
final class UncertainConfigurationResource extends ValueEditPersistence {
  UncertainConfigurationResource(this.key, this.snapshot);

  @override
  final EditorResourceKey key;
  final EditorSnapshot snapshot;

  @override
  Set<Object> get reservations => {key};

  var _read = false;

  @override
  Future<EditorSnapshot?> refreshSnapshot() async {
    if (_read) throw StateError("The saved values cannot be read");
    _read = true;
    return snapshot;
  }

  @override
  PreparedCommit<TypedMutationResult> prepareValue(
    EditorSnapshot snapshot,
    EditorCommit changes,
  ) => PreparedCommit(
    id: "not-a-uuid",
    label: "Uncertain configuration",
    resources: reservations,
    send: () async => SubmissionResult.uncertain(
      message: "The response could not be confirmed",
      cause: StateError("response lost"),
      stackTrace: StackTrace.current,
    ),
  );
}

/// An owner over one text value saved as "Saved" at revision 1, released
/// with the test. [commit] replaces the default acknowledgement.
ValueEditing savedTextOwner({
  EditorCommitter? commit,
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
  ScopedWorkSession? session,
}) {
  final owner = fakeValueEditing(
    document: EditorDocument(
      rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
      confirmedValue: skir.DataValue.wrapStringValue("Saved"),
      revision: 1,
    ),
    validation: (path, value) => EditorMutationResult.applied(value),
    commitPolicy: policy,
    workspace: session,
    commit: commit,
  );
  addTearDown(owner.dispose);
  return owner;
}

/// An automatic owner over [savedTextOwner] whose saves wait for [reply],
/// counting each one in [sends].
final class AutosavingOwner {
  AutosavingOwner({ScopedWorkSession? session}) {
    owner = savedTextOwner(
      policy: EditorCommitPolicy.autosaveChanges,
      session: session,
      commit: (_) {
        sends++;
        return reply.future;
      },
    );
  }

  final reply = Completer<TypedMutationResult>();
  int sends = 0;
  late final ValueEditing owner;
}

/// The bound control of [owner], released with the test.
EditControl boundControl(ValueEditing owner) {
  final control = owner.bindControl();
  addTearDown(control.dispose);
  return control;
}

/// Owner of the identified value [id] in [session], persisted through
/// [persistence] or a scripted resource that acknowledges every save.
ValueEditing identifiedOwner(
  ScopedWorkSession session,
  String id, {
  EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  ScriptedValuePersistence? persistence,
}) {
  final boundary =
      persistence ??
      ScriptedValuePersistence(
        key: EditorResourceKey(scope: null, identity: id),
        current: textSnapshot(),
        commit: (capture) async => MutationSuccess(
          revision: capture.expectedRevision + 1,
          value: capture.rootValue,
        ),
      );
  final owner = ValueEditingRegistration(
    targetId: id,
    label: id,
    persistence: boundary,
    snapshot: boundary.current!,
    commitPolicy: policy,
  ).acquire(session);
  final lease = session.lease(
    WorkDriverId(domain: "value", scope: boundary.key),
  );
  addTearDown(lease.release);
  return owner;
}

/// A document of one text value [value] at [revision].
EditorDocument textDocument(String value, {int revision = 1}) => EditorDocument(
  rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
  catalog: CheckedEditorCatalog(skir.EditorCatalog.defaultInstance),
  confirmedValue: skir.DataValue.wrapStringValue(value),
  revision: revision,
);

/// An editor target [targetId] read as [label] over [textDocument] of
/// [value], accepting every edit and applied with its resource in [scope].
/// [commit] answers its saves; by default no save is expected.
ValueEditingRegistration textEditorTarget(
  Object targetId, {
  required String label,
  Object? scope,
  String value = "Original",
  EditorCommitter? commit,
}) => fakeEditorTarget(
  targetId: targetId,
  label: label,
  scope: scope,
  document: textDocument(value),
  commitPolicy: EditorCommitPolicy.applyResource,
  commit: commit ?? (_) async => throw StateError("No save expected"),
);

/// A text snapshot holding [value] at [revision], accepting every edit.
EditorSnapshot textSnapshot([String value = "Original", int revision = 1]) =>
    FakeEditorSnapshot(
      EditorDocument(
        rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
        confirmedValue: skir.DataValue.wrapStringValue(value),
        revision: revision,
      ),
      validation: acceptTestEditorMutation,
    );

/// Applies the pending edits of [owners] together, as the apply action does.
Future<void> applyOwners(List<ValueEditing> owners) =>
    const EditApplyCoordinator().apply(
      owners.map((owner) => owner.workspace.applyRequest(owner.groupId)),
    );

/// A title and color record value.
skir.DataValue titleAndColorValue({
  required String title,
  required String color,
}) => recordEditorValue({
  "title": skir.DataValue.wrapStringValue(title),
  "color": skir.DataValue.wrapStringValue(color),
});

/// A title and color record at revision 1, saved through [commit] after
/// [debounce] and scheduled through [scheduler] (a controlled one by default).
ValueEditing titleAndColorSource({
  required EditorCommitter commit,
  EditorDelayScheduler? scheduler,
  EditorJitterSource? jitter,
  Duration debounce = const Duration(milliseconds: 250),
}) {
  return fakeValueEditing(
    document: recordEditorDocument(
      {
        "title": skir.DataValue.wrapStringValue("Old"),
        "color": skir.DataValue.wrapStringValue("Red"),
      },
      {
        "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        "color": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      },
      1,
    ),
    validation: (path, value) => EditorMutationResult.applied(value),
    debounce: debounce,
    commit: commit,
    scheduler: scheduler ?? ControlledScheduler(),
    jitter: jitter,
  );
}

/// A scheduler that records each delay and runs every task at once, except
/// the debounce of 250 milliseconds, which stays pending.
final class RecordingScheduler implements EditorDelayScheduler {
  final delays = <Duration>[];

  @override
  EditorScheduledTask schedule(Duration delay) {
    delays.add(delay);
    if (delay == const Duration(milliseconds: 250)) {
      return ControlledScheduledTask();
    }
    return const CompletedScheduledTask();
  }
}

/// A task that has already run.
final class CompletedScheduledTask implements EditorScheduledTask {
  const CompletedScheduledTask();

  @override
  Future<EditorTaskCompletion> get completed =>
      Future<EditorTaskCompletion>.value(EditorTaskCompletion.executed);

  @override
  void cancel() {}
}

/// A scheduler whose tasks run only when the test executes them, and that
/// lets a test wait for the task scheduled at an index.
final class ControlledScheduler implements EditorDelayScheduler {
  final delays = <Duration>[];
  final tasks = <ControlledScheduledTask>[];
  final _waiters = <int, Completer<ControlledScheduledTask>>{};

  @override
  EditorScheduledTask schedule(Duration delay) {
    delays.add(delay);
    final task = ControlledScheduledTask();
    tasks.add(task);
    _waiters.remove(tasks.length - 1)?.complete(task);
    return task;
  }

  /// Completes with the task scheduled at [index], once it exists.
  Future<ControlledScheduledTask> scheduledAt(int index) {
    if (tasks.length > index) return Future.value(tasks[index]);
    return _waiters
        .putIfAbsent(index, Completer<ControlledScheduledTask>.new)
        .future;
  }
}

/// A task a test executes or cancels by hand.
final class ControlledScheduledTask implements EditorScheduledTask {
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

/// A jitter source that always returns [value], which must not exceed the
/// maximum it is asked for.
final class FixedJitter implements EditorJitterSource {
  const FixedJitter(this.value);

  final Duration value;

  @override
  Duration next(Duration maximum) {
    assert(value <= maximum, "Test jitter must not exceed its maximum.");
    return value;
  }
}

/// The text resource `first` whose first refresh waits for [releaseRead]
/// after completing [readStarted], and whose reservations grow by `extra`
/// once [widen] is set; it counts its refreshes in [reads] and acknowledges
/// every save at revision 2.
final class GatedReadPersistence extends ScriptedValuePersistence {
  GatedReadPersistence()
    : super(
        key: const EditorResourceKey(scope: null, identity: "first"),
        current: textSnapshot(),
        commit: (capture) async =>
            MutationSuccess(revision: 2, value: capture.rootValue),
      );
  bool widen = false;
  int reads = 0;
  final readStarted = Completer<void>();
  final releaseRead = Completer<void>();
  @override
  Set<Object> get reservations => {key, if (widen) "extra"};
  @override
  Future<EditorSnapshot?> refreshSnapshot() async {
    if (++reads == 1) {
      readStarted.complete();
      await releaseRead.future;
    }
    return current;
  }
}

/// Owners of the identified values "first" and "second" in [session], both
/// committing under [policy].
({ValueEditing first, ValueEditing second}) identifiedPair(
  ScopedWorkSession session, {
  EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
}) => (
  first: identifiedOwner(session, "first", policy: policy),
  second: identifiedOwner(session, "second", policy: policy),
);

/// A [titleAndColorSource] on a controlled scheduler whose title was just
/// edited to "New": [task] is the debounced commit it waits on, and every
/// commit records in [commits] and saves "New" in red.
({ValueEditing source, ControlledScheduledTask task}) debouncedTitleEdit(
  List<EditorCommit> commits,
) {
  final scheduler = ControlledScheduler();
  final source = titleAndColorSource(
    scheduler: scheduler,
    commit: recordingCommit(
      commits,
      titleAndColorValue(title: "New", color: "Red"),
    ),
  );
  source.update(
    editorRootPath.field("title"),
    skir.DataValue.wrapStringValue("New"),
  );
  return (source: source, task: scheduler.tasks.single);
}
