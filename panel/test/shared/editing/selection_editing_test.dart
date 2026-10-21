import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

final _catalog = skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog();
skir.DataValue _text(String value) => skir.DataValue.wrapStringValue(value);
EditorSnapshot _snapshot([String value = "Original", int revision = 1]) =>
    FakeEditorSnapshot(
      EditorDocument(
        rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        catalog: _catalog,
        confirmedValue: _text(value),
        revision: revision,
      ),
      validation: acceptTestEditorMutation,
    );

ValueEditing _owner(
  ScopedWorkSession session,
  String id, {
  EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
  ScriptedValuePersistence? persistence,
}) {
  final boundary =
      persistence ??
      ScriptedValuePersistence(
        key: EditorResourceKey(scope: null, identity: id),
        current: _snapshot(),
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

Future<void> _apply(List<ValueEditing> owners) => const EditApplyCoordinator()
    .apply(owners.map((owner) => owner.workspace.applyRequest(owner.groupId)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    "every authoritative read completes before any request starts",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final events = <String>[];
      ScriptedValuePersistence boundary(String id) => ScriptedValuePersistence(
        key: EditorResourceKey(scope: null, identity: id),
        current: _snapshot(),
        load: () async {
          events.add("read $id");
          return _snapshot();
        },
        commit: (capture) async {
          expect(events.take(2), ["read first", "read second"]);
          events.add("send $id");
          return MutationSuccess(revision: 2, value: capture.rootValue);
        },
      );
      final first = _owner(session, "first", persistence: boundary("first"));
      final second = _owner(session, "second", persistence: boundary("second"));
      first.update(editorRootPath, _text("First"));
      second.update(editorRootPath, _text("Second"));
      await _apply([first, second]);
      expect(events, [
        "read first",
        "read second",
        "send first",
        "send second",
      ]);
      expect(first.hasWork || second.hasWork, isFalse);
    },
  );

  test(
    "one failed preparation prevents every send and preserves proposals",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      var sends = 0;
      ScriptedValuePersistence boundary(String id, bool fail) =>
          ScriptedValuePersistence(
            key: EditorResourceKey(scope: null, identity: id),
            current: _snapshot(),
            load: () async {
              if (fail) throw StateError("Unavailable");
              return _snapshot();
            },
            commit: (capture) async {
              sends++;
              return MutationSuccess(revision: 2, value: capture.rootValue);
            },
          );
      final first = _owner(
        session,
        "first",
        persistence: boundary("first", false),
      );
      final second = _owner(
        session,
        "second",
        persistence: boundary("second", true),
      );
      first.update(editorRootPath, _text("First"));
      second.update(editorRootPath, _text("Second"));
      await _apply([first, second]);
      expect(sends, 0);
      expect(first.value(editorRootPath).valueOrNull, _text("First"));
      expect(second.value(editorRootPath).valueOrNull, _text("Second"));
    },
  );

  test("a conflicting observation blocks the complete cohort", () async {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    var sends = 0;
    final boundary = ScriptedValuePersistence(
      key: const EditorResourceKey(scope: null, identity: "second"),
      current: _snapshot(),
      load: () async => _snapshot("Remote", 2),
      commit: (capture) async {
        sends++;
        return MutationSuccess(revision: 3, value: capture.rootValue);
      },
    );
    final first = _owner(session, "first");
    final second = _owner(session, "second", persistence: boundary);
    first.update(editorRootPath, _text("First"));
    second.update(editorRootPath, _text("Second"));
    await _apply([first, second]);
    expect(sends, 0);
    expect(first.document.revision, 1);
    expect(second.saveState(editorRootPath).phase, EditorSavePhase.conflict);
    expect(second.value(editorRootPath).valueOrNull, _text("Second"));
  });

  test(
    "manual interactions stage together and release without sending",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final first = _owner(
        session,
        "first",
        policy: EditorCommitPolicy.applyResource,
      );
      final second = _owner(
        session,
        "second",
        policy: EditorCommitPolicy.applyResource,
      );
      final combined = MultiEditOwner(
        owners: [first, second],
        rootType: first.rootType,
        catalog: first.catalog,
      );
      addTearDown(combined.dispose);
      final interaction = combined.beginInteraction(editorRootPath);
      expect(
        combined.update(editorRootPath, _text("Draft")),
        isA<AppliedEditorMutation>(),
      );
      await interaction.commit();
      expect(interaction.active, isFalse);
      expect(session.submissions, isEmpty);
      final control = combined.bindControl();
      addTearDown(control.dispose);
      expect(control.state.canApply, isTrue);
      await control.apply();
      expect(session.submissions, hasLength(2));
      expect(control.state.hasWork, isFalse);
    },
  );

  test(
    "cancelling selection interactions preserves earlier local work",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final first = _owner(
        session,
        "first",
        policy: EditorCommitPolicy.applyResource,
      );
      final second = _owner(
        session,
        "second",
        policy: EditorCommitPolicy.applyResource,
      );
      first.update(editorRootPath, _text("Earlier"));
      final combined = MultiEditOwner(
        owners: [first, second],
        rootType: first.rootType,
        catalog: first.catalog,
      );
      addTearDown(combined.dispose);
      final interaction = combined.beginInteraction(editorRootPath);
      combined.update(editorRootPath, _text("Draft"));
      interaction.cancel();
      expect(first.value(editorRootPath).valueOrNull, _text("Earlier"));
      expect(second.value(editorRootPath).valueOrNull, _text("Original"));
      expect(session.submissions, isEmpty);
    },
  );

  test("concurrent selection Apply claims the shared lanes once", () async {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final first = _owner(
      session,
      "first",
      policy: EditorCommitPolicy.applyResource,
    );
    final second = _owner(
      session,
      "second",
      policy: EditorCommitPolicy.applyResource,
    );
    first.update(editorRootPath, _text("First"));
    second.update(editorRootPath, _text("Second"));
    await Future.wait([
      _apply([first, second]),
      _apply([second, first]),
    ]);
    expect(session.submissions, hasLength(2));
    expect(first.hasWork || second.hasWork, isFalse);
  });

  test("duplicate request identities produce one server request", () async {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final source = _owner(
      session,
      "first",
      policy: EditorCommitPolicy.applyResource,
    )..update(editorRootPath, _text("Draft"));
    await _apply([source, source]);
    expect(session.submissions, hasLength(1));
    expect(source.hasWork, isFalse);
  });

  test("independent server boundaries preserve partial outcomes", () async {
    final session = ScopedWorkSession();
    addTearDown(session.dispose);
    final boundary = ScriptedValuePersistence(
      key: const EditorResourceKey(scope: null, identity: "second"),
      current: _snapshot(),
      commit: (_) async => MutationUncertain(
        message: "Lost reply",
        cause: StateError("Lost reply"),
        stackTrace: StackTrace.current,
      ),
    );
    final first = _owner(session, "first");
    final second = _owner(session, "second", persistence: boundary);
    first.update(editorRootPath, _text("First"));
    second.update(editorRootPath, _text("Second"));
    await _apply([first, second]);
    expect(first.hasWork, isFalse);
    final released = await session
        .reserve(first.workspace.persistence.reservationsFor(const []))
        .timeout(const Duration(seconds: 2));
    released.release();
    expect(second.hasWork, isTrue);
    expect(second.saveState(editorRootPath).phase, EditorSavePhase.uncertain);
    expect(session.submissions, hasLength(2));
    final control = EditSelectionControl([
      first.bindControl(),
      second.bindControl(),
    ]);
    addTearDown(control.dispose);
    expect(control.state.canApply, isFalse);
    expect(control.state.canRetry, isFalse);
    await control.apply();
    expect(session.submissions, hasLength(2));
  });

  test(
    "queued preparation captures edits only after owning reservations",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      var reads = 0;
      final boundary = ScriptedValuePersistence(
        key: const EditorResourceKey(scope: null, identity: "first"),
        current: _snapshot(),
        load: () async {
          reads++;
          return _snapshot();
        },
        commit: (capture) async {
          expect(capture.rootValue, _text("Latest"));
          return MutationSuccess(revision: 2, value: capture.rootValue);
        },
      );
      final source = _owner(session, "first", persistence: boundary)
        ..update(editorRootPath, _text("Draft"));
      final held = await session.reserve(boundary.reservations);
      final applying = _apply([source]);
      await Future<void>.delayed(Duration.zero);
      expect(reads, 0);
      source.update(editorRootPath, _text("Latest"));
      held.release();
      await applying;
      expect(reads, 1);
      expect(source.hasWork, isFalse);
    },
  );

  test(
    "widening a request releases its partial reservation before waiting",
    () async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final boundary = _WideningPersistence();
      final source = _owner(session, "first", persistence: boundary)
        ..update(editorRootPath, _text("Draft"));
      final extra = await session.reserve({"extra"});
      final applying = _apply([source]);
      await boundary.readStarted.future;
      boundary.widen = true;
      boundary.releaseRead.complete();
      await Future<void>.delayed(Duration.zero);
      final probe = session.reserve({boundary.key});
      extra.release();
      await applying;
      (await probe.timeout(const Duration(seconds: 2))).release();
      expect(boundary.reads, 2);
      expect(source.hasWork, isFalse);
    },
  );
}

final class _WideningPersistence extends ScriptedValuePersistence {
  _WideningPersistence()
    : super(
        key: const EditorResourceKey(scope: null, identity: "first"),
        current: _snapshot(),
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
