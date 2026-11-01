import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    "every authoritative read completes before any request starts",
    () async {
      final session = testWorkSession();
      final events = <String>[];
      ScriptedValuePersistence boundary(String id) => ScriptedValuePersistence(
        key: EditorResourceKey(scope: null, identity: id),
        current: textSnapshot(),
        load: () async {
          events.add("read $id");
          return textSnapshot();
        },
        commit: (capture) async {
          expect(events.take(2), ["read first", "read second"]);
          events.add("send $id");
          return MutationSuccess(revision: 2, value: capture.rootValue);
        },
      );
      final first = identifiedOwner(
        session,
        "first",
        persistence: boundary("first"),
      );
      final second = identifiedOwner(
        session,
        "second",
        persistence: boundary("second"),
      );
      first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
      second.update(editorRootPath, skir.DataValue.wrapStringValue("Second"));
      await applyOwners([first, second]);
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
      final session = testWorkSession();
      var sends = 0;
      ScriptedValuePersistence boundary(String id, bool fail) =>
          ScriptedValuePersistence(
            key: EditorResourceKey(scope: null, identity: id),
            current: textSnapshot(),
            load: () async {
              if (fail) throw StateError("Unavailable");
              return textSnapshot();
            },
            commit: (capture) async {
              sends++;
              return MutationSuccess(revision: 2, value: capture.rootValue);
            },
          );
      final first = identifiedOwner(
        session,
        "first",
        persistence: boundary("first", false),
      );
      final second = identifiedOwner(
        session,
        "second",
        persistence: boundary("second", true),
      );
      first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
      second.update(editorRootPath, skir.DataValue.wrapStringValue("Second"));
      await applyOwners([first, second]);
      expect(sends, 0);
      expect(
        first.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("First"),
      );
      expect(
        second.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("Second"),
      );
    },
  );

  test("a conflicting observation blocks the complete cohort", () async {
    final session = testWorkSession();
    var sends = 0;
    final boundary = ScriptedValuePersistence(
      key: const EditorResourceKey(scope: null, identity: "second"),
      current: textSnapshot(),
      load: () async => textSnapshot("Remote", 2),
      commit: (capture) async {
        sends++;
        return MutationSuccess(revision: 3, value: capture.rootValue);
      },
    );
    final first = identifiedOwner(session, "first");
    final second = identifiedOwner(session, "second", persistence: boundary);
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    second.update(editorRootPath, skir.DataValue.wrapStringValue("Second"));
    await applyOwners([first, second]);
    expect(sends, 0);
    expect(first.document.revision, 1);
    expect(second.saveState(editorRootPath).phase, EditorSavePhase.conflict);
    expect(
      second.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Second"),
    );
  });

  test(
    "manual interactions stage together and release without sending",
    () async {
      final session = testWorkSession();
      final (:first, :second) = identifiedPair(
        session,
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
        combined.update(
          editorRootPath,
          skir.DataValue.wrapStringValue("Draft"),
        ),
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
      final session = testWorkSession();
      final (:first, :second) = identifiedPair(
        session,
        policy: EditorCommitPolicy.applyResource,
      );
      first.update(editorRootPath, skir.DataValue.wrapStringValue("Earlier"));
      final combined = MultiEditOwner(
        owners: [first, second],
        rootType: first.rootType,
        catalog: first.catalog,
      );
      addTearDown(combined.dispose);
      final interaction = combined.beginInteraction(editorRootPath);
      combined.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      interaction.cancel();
      expect(
        first.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("Earlier"),
      );
      expect(
        second.value(editorRootPath).valueOrNull,
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(session.submissions, isEmpty);
    },
  );

  test("concurrent selection Apply claims the shared lanes once", () async {
    final session = testWorkSession();
    final (:first, :second) = identifiedPair(
      session,
      policy: EditorCommitPolicy.applyResource,
    );
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    second.update(editorRootPath, skir.DataValue.wrapStringValue("Second"));
    await Future.wait([
      applyOwners([first, second]),
      applyOwners([second, first]),
    ]);
    expect(session.submissions, hasLength(2));
    expect(first.hasWork || second.hasWork, isFalse);
  });

  test("duplicate request identities produce one server request", () async {
    final session = testWorkSession();
    final source = identifiedOwner(
      session,
      "first",
      policy: EditorCommitPolicy.applyResource,
    )..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await applyOwners([source, source]);
    expect(session.submissions, hasLength(1));
    expect(source.hasWork, isFalse);
  });

  test("independent server boundaries preserve partial outcomes", () async {
    final session = testWorkSession();
    final boundary = ScriptedValuePersistence(
      key: const EditorResourceKey(scope: null, identity: "second"),
      current: textSnapshot(),
      commit: (_) async {
        return MutationUncertain(
          message: "Lost reply",
          cause: StateError("Lost reply"),
          stackTrace: StackTrace.current,
        );
      },
    );
    final first = identifiedOwner(session, "first");
    final second = identifiedOwner(session, "second", persistence: boundary);
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    second.update(editorRootPath, skir.DataValue.wrapStringValue("Second"));
    await applyOwners([first, second]);
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
      final session = testWorkSession();
      var reads = 0;
      final boundary = ScriptedValuePersistence(
        key: const EditorResourceKey(scope: null, identity: "first"),
        current: textSnapshot(),
        load: () async {
          reads++;
          return textSnapshot();
        },
        commit: (capture) async {
          expect(capture.rootValue, skir.DataValue.wrapStringValue("Latest"));
          return MutationSuccess(revision: 2, value: capture.rootValue);
        },
      );
      final source = identifiedOwner(session, "first", persistence: boundary)
        ..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      final held = await session.reserve(boundary.reservations);
      final applying = applyOwners([source]);
      await Future<void>.delayed(Duration.zero);
      expect(reads, 0);
      source.update(editorRootPath, skir.DataValue.wrapStringValue("Latest"));
      held.release();
      await applying;
      expect(reads, 1);
      expect(source.hasWork, isFalse);
    },
  );

  test(
    "widening a request releases its partial reservation before waiting",
    () async {
      final session = testWorkSession();
      final boundary = GatedReadPersistence();
      final source = identifiedOwner(session, "first", persistence: boundary)
        ..update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      final extra = await session.reserve({"extra"});
      final applying = applyOwners([source]);
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
