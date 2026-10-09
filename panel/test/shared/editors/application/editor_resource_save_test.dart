import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/editor_fixture.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");
skir.DataValue _value(String title) =>
    recordEditorValue({"title": skir.DataValue.wrapStringValue(title)});

final _fieldTypes = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};
EditorSnapshot _snapshot({String title = "Original", int revision = 1}) =>
    FakeEditorSnapshot(
      recordEditorDocument(
        {"title": skir.DataValue.wrapStringValue(title)},
        _fieldTypes,
        revision,
      ),
      validation: acceptTestEditorMutation,
    );
TransactionalEditorSource _draft(
  ScopedWorkSession workspace,
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
  source.update(_title, skir.DataValue.wrapStringValue("Draft"));
  return source;
}

void main() {
  test(
    "detached save waits for its reservation before reading and capturing",
    () async {
      final workspace = ScopedWorkSession();
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
    final workspace = ScopedWorkSession();
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
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(source.document.confirmedValue, _value("Remote"));
  });

  test(
    "refresh failure releases the reservation and retains a retryable draft",
    () async {
      final workspace = ScopedWorkSession();
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
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);
    final resource = FakeEditableResource(
      key: _key,
      current: null,
      commit: (_) async => throw StateError("Unexpected send"),
    );
    final source = _draft(workspace, resource);
    expect(await source.flush(), isA<MutationUnavailable>());
    expect(
      source.saveState(editorRootPath).phase,
      EditorSavePhase.deletedElsewhere,
    );
  });

  test("workspace disposal during refresh prevents submission", () async {
    final workspace = ScopedWorkSession();
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
      final workspace = ScopedWorkSession();
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
    final workspace = ScopedWorkSession();
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
