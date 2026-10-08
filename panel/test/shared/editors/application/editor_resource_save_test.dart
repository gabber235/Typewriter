import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = DataPath.root.field("title");
RecordValue _value(String title) => RecordValue({"title": StringValue(title)});
EditorSnapshot _snapshot({String title = "Original", int revision = 1}) =>
    FakeEditorSnapshot(
      EditorDocument(
        rootType: RecordType(
          fields: const {"title": TypeField(name: "title", type: StringType())},
        ),
        typeCatalog: const TypeCatalog([]),
        confirmedValue: _value(title),
        revision: revision,
      ),
      validation: acceptTestEditorMutation,
    );
TransactionalEditorSource _draft(
  LocalWorkSession workspace,
  EditableResource resource,
) {
  final source = workspace.editor(
    ResourceEditorTarget(
      targetId: resource.key.identity,
      label: "Resource",
      resource: resource,
      snapshot: _snapshot(),
      commitPolicy: EditorCommitPolicy.applyResource,
    ),
  ) as TransactionalEditorSource;
  workspace.retain(resource.key);
  source.update(_title, const StringValue("Draft"));
  return source;
}

void main() {
  test(
    "detached save waits for its reservation before reading and capturing",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      var reads = 0;
      final resource = FakeEditableResource(
        key: _key,
        current: _snapshot(),
        load: () async {
          reads++;
          return _snapshot(revision: 2);
        },
        commit: (commit) async {
          expect(commit.expectedRevision, 2);
          expect(commit.rootValue, _value("Draft"));
          return MutationSuccess(revision: 3, value: commit.rootValue);
        },
      );
      final predecessor = await workspace.coordinator.reserve(
        resource.reservations,
      );
      final source = _draft(workspace, resource);

      workspace.release(_key);
      final saving = source.flush();
      await pumpEventQueue();
      expect(reads, 0);
      expect(workspace.resources, contains(_key));
      predecessor.release();

      expect(await saving, isA<MutationSuccess>());
      expect(reads, 1);
    },
  );

  test("refresh conflicts preserve the draft and prevent sending", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    var sends = 0;
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(title: "Remote", revision: 2),
      commit: (_) async {
        sends++;
        throw StateError("Unexpected send");
      },
    );
    final source = _draft(workspace, resource);
    expect(await source.flush(), isA<MutationUnavailable>());

    expect(sends, 0);
    expect(source.value(_title).valueOrNull, const StringValue("Draft"));
    expect(source.document.confirmedValue, _value("Remote"));
  });

  test(
    "refresh failure releases the reservation and retains a retryable draft",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      var reads = 0;
      final resource = FakeEditableResource(
        key: _key,
        current: _snapshot(),
        load: () async {
          if (++reads == 1) throw TimeoutException("Offline");
          return _snapshot();
        },
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      );
      final source = _draft(workspace, resource);
      expect(await source.flush(), isA<MutationUnavailable>());

      expect(source.hasWork, isTrue);
      expect(await source.flush(), isA<MutationSuccess>());
      expect(reads, 2);
    },
  );

  test("confirmed deletion blocks submission", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final resource = FakeEditableResource(
      key: _key,
      current: null,
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);
    expect(await source.flush(), isA<MutationUnavailable>());
    expect(
      source.saveState(DataPath.root).phase,
      EditorSavePhase.deletedElsewhere,
    );
  });

  test("workspace disposal during refresh prevents submission", () async {
    final workspace = LocalWorkSession();
    final ready = Completer<EditorSnapshot?>();
    final started = Completer<void>();
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(),
      load: () {
        started.complete();
        return ready.future;
      },
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);
    final saving = source.flush();

    await started.future;
    workspace.dispose();
    ready.complete(_snapshot());
    expect(await saving, isA<MutationUnavailable>());
  });

  test(
    "uncertain delivery retains the reservation and replays without refresh",
    () async {
      final workspace = LocalWorkSession();
      addTearDown(workspace.dispose);
      final resource = _UncertainResource();
      final source = _draft(workspace, resource);
      expect(await source.flush(), isA<MutationUncertain>());
      var acquired = false;

      final next = workspace.coordinator.reserve(resource.reservations).then((
        lease,
      ) {
        acquired = true;
        return lease;
      });
      await pumpEventQueue();
      expect(acquired, isFalse);
      expect(await source.flush(), isA<MutationSuccess>());
      (await next).release();
      expect(resource.reads, 1);

      expect(resource.sends, 2);
      expect(resource.requests[0], same(resource.requests[1]));
    },
  );

  test("concurrent flushes share one refresh and submission", () async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final ready = Completer<EditorSnapshot?>();
    var reads = 0;
    var sends = 0;
    final resource = FakeEditableResource(
      key: _key,
      current: _snapshot(),
      load: () {
        reads++;
        return ready.future;
      },
      commit: (commit) async {
        sends++;
        return MutationSuccess(revision: 2, value: commit.rootValue);
      },
    );

    final source = _draft(workspace, resource);
    final first = source.flush();
    final second = source.flush();
    ready.complete(_snapshot());
    expect(await first, isA<MutationSuccess>());
    expect(await second, isA<MutationSuccess>());

    expect(reads, 1);
    expect(sends, 1);
  });
}

final class _UncertainResource extends FakeEditableResource {
  _UncertainResource()
    : super(
        key: _key,
        current: _snapshot(),
        commit: (_) async => throw StateError("Use captured request"),
      );
  int reads = 0;
  int sends = 0;
  final requests = <EditorCommit>[];

  @override
  Future<EditorSnapshot?> refresh() async {
    reads++;
    return current;
  }

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit changes,
    void Function(TypedMutationResult) accept,
  ) => IndependentMutation(
    PendingCommit(
      resources: reservations,
      prepare: () => PreparedCommit<EditorCommit>(
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
          return SubmissionResult.confirmed(changes);
        },
        integrate: (result) async {
          if (result case SubmissionConfirmed(:final value)) {
            accept(MutationSuccess(revision: 2, value: value.rootValue));
          }
        },
      ),
    ),
  );
}
