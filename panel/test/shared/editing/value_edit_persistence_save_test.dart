import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _key = EditorResourceKey(
  scope: "original organization",
  identity: "resource",
);
final _title = editorRootPath.field("title");
void main() {
  test(
    "detached save waits for its reservation before reading and capturing",
    () async {
      final workspace = testWorkSession();
      var reads = 0;
      final resource = ScriptedValuePersistence(
        key: _key,
        current: savedTitleSnapshot(),
        load: () async {
          reads++;
          return savedTitleSnapshot(revision: 2);
        },
        commit: (commit) async {
          expect(commit.expectedRevision, 2);
          expect(commit.rootValue, titleValue("Draft"));
          return MutationSuccess(revision: 3, value: commit.rootValue);
        },
      );
      final predecessor = await workspace.coordinator.reserve(
        resource.reservations,
      );
      final source = titleDraft(workspace, resource);

      workspace.lease(WorkDriverId(domain: "value", scope: _key)).release();
      final saving = source.flush();
      await pumpEventQueue();
      expect(reads, 0);
      expect(source.workspace.closed, isFalse);
      predecessor.release();

      expect(await saving, isA<MutationSuccess>());
      expect(reads, 1);
    },
  );

  test("refresh conflicts preserve the draft and prevent sending", () async {
    final workspace = testWorkSession();
    final reports = captureFlutterErrors();
    var sends = 0;
    final resource = ScriptedValuePersistence(
      key: _key,
      current: savedTitleSnapshot(title: "Remote", revision: 2),
      commit: (_) async {
        sends++;
        throw StateError("Unexpected send");
      },
    );
    final source = titleDraft(workspace, resource);
    expect(await source.flush(), isA<MutationUnavailable>());

    expect(sends, 0);
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(source.document.confirmedValue, titleValue("Remote"));
    expect(reports, isEmpty);
  });

  test(
    "refresh failure releases the reservation and retains a retryable draft",
    () async {
      final workspace = testWorkSession();
      var reads = 0;
      final resource = ScriptedValuePersistence(
        key: _key,
        current: savedTitleSnapshot(),
        load: () async {
          if (++reads == 1) throw TimeoutException("Offline");
          return savedTitleSnapshot();
        },
        commit: (commit) async =>
            MutationSuccess(revision: 2, value: commit.rootValue),
      );
      final source = titleDraft(workspace, resource);
      expect(await source.flush(), isA<MutationUnavailable>());

      expect(source.hasWork, isTrue);
      expect(await source.flush(), isA<MutationSuccess>());
      expect(reads, 2);
    },
  );

  test("confirmed deletion blocks submission", () async {
    final workspace = testWorkSession();
    final reports = captureFlutterErrors();
    var sends = 0;
    final resource = ScriptedValuePersistence(
      key: _key,
      current: null,
      commit: (_) async {
        sends++;
        throw StateError("Unexpected send");
      },
    );
    final source = titleDraft(workspace, resource);
    expect(await source.flush(), isA<MutationUnavailable>());
    expect(
      source.saveState(editorRootPath).phase,
      EditorSavePhase.deletedElsewhere,
    );
    expect(sends, 0);
    expect(reports, isEmpty);
  });

  test("workspace disposal during refresh prevents submission", () async {
    final workspace = ScopedWorkSession();
    final reports = captureFlutterErrors();
    final ready = Completer<EditorSnapshot?>();
    final started = Completer<void>();
    var sends = 0;
    final resource = ScriptedValuePersistence(
      key: _key,
      current: savedTitleSnapshot(),
      load: () {
        started.complete();
        return ready.future;
      },
      commit: (_) async {
        sends++;
        throw StateError("Unexpected send");
      },
    );
    final source = titleDraft(workspace, resource);
    final saving = source.flush();

    await started.future;
    workspace.dispose();
    ready.complete(savedTitleSnapshot());
    expect(await saving, isA<MutationUnavailable>());
    expect(sends, 0);
    expect(reports, isEmpty);
  });

  test(
    "uncertain delivery retains the reservation and replays without refresh",
    () async {
      final workspace = testWorkSession();
      final resource = UncertainSaveResource(
        key: _key,
        current: savedTitleSnapshot(),
      );
      final source = titleDraft(workspace, resource);
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
    final workspace = testWorkSession();
    final ready = Completer<EditorSnapshot?>();
    var reads = 0;
    var sends = 0;
    final resource = ScriptedValuePersistence(
      key: _key,
      current: savedTitleSnapshot(),
      load: () {
        reads++;
        return ready.future;
      },
      commit: (commit) async {
        sends++;
        return MutationSuccess(revision: 2, value: commit.rootValue);
      },
    );

    final source = titleDraft(workspace, resource);
    final first = source.flush();
    final second = source.flush();
    ready.complete(savedTitleSnapshot());
    expect(await first, isA<MutationSuccess>());
    expect(await second, isA<MutationSuccess>());

    expect(reads, 1);
    expect(sends, 1);
  });
}
