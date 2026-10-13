import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

skir.DataValue _text(String value) => skir.DataValue.wrapStringValue(value);
final _page = skir.ResourceId(value: "page:contract");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _contract<ValueEditDocument, ValueEdit>(
    "Value model",
    model: const ValueEditModel(),
    initial: () => ValueEditDocument.fromSnapshot(
      FakeEditorSnapshot(
        EditorDocument(
          rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
          catalog: skir.EditorCatalogWireSnapshot.defaultInstance
              .asTrustedLocalCatalog(),
          confirmedValue: _text("Original"),
          revision: 1,
        ),
        validation: acceptTestEditorMutation,
      ),
      identity: "contract",
    ),
    change: (document, value) => ValueEdit(
      baseline: document,
      proposed: _text(value),
      paths: {editorRootPath},
      mutations: [EditorSetValue(editorRootPath, _text(value))],
    ),
    read: (document) => document.value.authoredString!,
    accepted: (document) => document.copyWith(
      metadata: ResultEditorSnapshot(
        document.metadata,
        document.metadata.document.copyWith(
          revision: document.revision + 1,
          confirmedValue: document.value,
        ),
      ),
    ),
    inspectActiveSave: (owner, group) {
      final value = ValueEditing.fromWorkspace(owner, group);
      final status = value.saveState(editorRootPath);
      expect(status.phase, EditorSavePhase.saving);
      expect(status.diagnostics, isEmpty);
    },
  );
  _contract<AuthoringDocument, RealmPreparedEdit>(
    "Realm model",
    model: const RealmEditModel(),
    initial: () => fixtureAuthoringDocument(
      pages: [
        Page(
          pageId: _page,
          bookId: null,
          name: "Original",
          configuration: skir.TypeSelection.unknown,
          chapter: "Introduction",
          priority: 0,
        ),
      ],
    ),
    change: (document, value) {
      final edit = AuthoringEdit.fromDocument(document)
        ..set(
          skir.ValueLocation(
            resource: _page,
            path: editorRootPath.field("name"),
          ),
          _text(value),
        );
      return RealmPreparedEdit(request: edit.prepare());
    },
    read: (document) =>
        document.resource(_page)!.authoredField("name")!.authoredString!,
    accepted: (document) => document.copyWith(revision: document.revision + 1),
  );
}

void _contract<S, E>(
  String label, {
  required EditModel<S, E> model,
  required S Function() initial,
  required E Function(S document, String value) change,
  required String Function(S document) read,
  required S Function(S document) accepted,
  void Function(EditingWorkspace<S, E> owner, EditGroupId group)?
  inspectActiveSave,
}) {
  group(label, () {
    late ScopedWorkSession session;
    late _Boundary<S, E> boundary;
    late EditingWorkspace<S, E> owner;
    late EditingWorkDriver<S, E> driver;
    late EditGroupId id;
    late EditGroupControl<S, E> control;
    setUp(() {
      session = ScopedWorkSession();
      boundary = _Boundary(initial(), accepted);
      owner = EditingWorkspace(
        model: model,
        persistence: boundary,
        submissions: session,
        initial: boundary.current,
      );
      driver = EditingWorkDriver(
        id: WorkDriverId(domain: "editing", scope: label),
        workspace: owner,
      );
      id = owner.createGroup(
        label: "Edit name",
        policy: EditorCommitPolicy.applyResource,
        admission: EditWriteAdmission.allowWhileSubmitted,
      );
      control = owner.group(id);
    });
    tearDown(() {
      control.dispose();
      driver.dispose();
      session.dispose();
    });
    void stage(String value) =>
        owner.stage(id, change(owner.document, value)).requireAccepted();

    test("an acknowledged save remains active while refreshing and retains later edits", () async {
      final reply = boundary.reply = Completer();
      final observation = boundary.refreshReply = Completer();
      stage("Draft");
      final applying = control.apply();
      await boundary.started.future;
      reply.complete(const SubmissionConfirmed(EditAccepted()));
      await boundary.observing.future;

      final entry = driver.snapshot.entries.single;
      expect(entry.needsAttention, isFalse);
      expect(entry.saving, isTrue);
      expect(entry.phase, "Changes were applied. Refreshing saved values");
      expect(control.state.canApply, isFalse);
      expect(control.state.hasSubmittedWork, isTrue);
      inspectActiveSave?.call(owner, id);

      stage("Later");
      expect(boundary.captures, hasLength(1));
      observation.complete(accepted(boundary.captures.single.proposed));
      await applying;
      expect(read(owner.confirmed), "Draft");
      expect(read(owner.document), "Later");
      expect(control.state.canApply, isTrue);
      await control.apply();
      expect(read(owner.confirmed), "Later");
      expect(boundary.captures, hasLength(2));
      expect(control.state.hasWork, isFalse);
    });
    test(
      "Apply settles one request and the same owner accepts another edit",
      () async {
        expect(control.state.hasWork, isFalse);
        stage("Draft");
        expect(control.state.canApply, isTrue);
        expect(read(owner.confirmed), "Original");
        await control.apply();
        expect(control.state.hasWork, isFalse);
        expect(read(owner.confirmed), "Draft");
        stage("Next");
        await control.apply();
        expect(read(owner.confirmed), "Next");
        expect(boundary.captures, hasLength(2));
        expect(control.state.hasWork, isFalse);
      },
    );
    test("reverting pending intent creates no request", () async {
      stage("Draft");
      stage("Original");
      expect(control.state.hasWork, isFalse);
      await control.apply();
      expect(boundary.captures, isEmpty);
    });
    test(
      "a submitted prefix settles independently of its later local tail",
      () async {
        final reply = boundary.reply = Completer();
        stage("Draft");
        final applying = control.apply();
        await boundary.started.future;
        stage("Later");
        reply.complete(
          SubmissionConfirmed(
            EditConfirmed(accepted(boundary.captures.single.proposed)),
          ),
        );
        await applying;
        expect(read(owner.confirmed), "Draft");
        expect(read(owner.document), "Later");
        expect(control.state.canApply, isTrue);
        await control.apply();
        expect(read(owner.confirmed), "Later");
        expect(boundary.captures, hasLength(2));
      },
    );
    test(
      "Discard removes only unsent work while a request is pending",
      () async {
        final reply = boundary.reply = Completer();
        stage("Draft");
        final applying = control.apply();
        await boundary.started.future;
        stage("Later");
        expect(control.discard(), isTrue);
        expect(read(owner.document), "Draft");
        expect(control.state.hasSubmittedWork, isTrue);
        expect(control.state.canDiscard, isFalse);
        reply.complete(
          SubmissionConfirmed(
            EditConfirmed(accepted(boundary.captures.single.proposed)),
          ),
        );
        await applying;
        expect(control.state.hasWork, isFalse);
        expect(boundary.captures, hasLength(1));
      },
    );
    test(
      "unknown delivery preserves the request without unsupported replay",
      () async {
        final reply = boundary.reply = Completer();
        stage("Draft");
        final applying = control.apply();
        await boundary.started.future;
        reply.complete(
          SubmissionUncertain(
            message: "Reply lost",
            cause: StateError("Reply lost"),
            stackTrace: StackTrace.current,
          ),
        );
        await applying;
        expect(control.state.hasWork, isTrue);
        expect(control.state.hasSubmittedWork, isTrue);
        expect(control.state.canApply, isFalse);
        expect(control.state.canDiscard, isFalse);
        expect(control.state.canRetry, isFalse);
        await control.apply();
        expect(boundary.captures, hasLength(1));
        expect(read(owner.document), "Draft");
      },
    );
  });
}

/// Controls only authoritative observations and replies for the shared contract.
final class _Boundary<S, E> implements EditPersistence<S, E> {
  _Boundary(this.current, this.accepted);
  S current;
  final S Function(S) accepted;
  final key = Object();
  final captures = <EditCapture<S, E>>[];
  final started = Completer<void>();
  final observing = Completer<void>();
  Completer<SubmissionResult<EditSettlement<S>>>? reply;
  Completer<S>? refreshReply;
  @override
  Set<Object> reservationsFor(Iterable<E> pendingEdits) => {key};
  @override
  Future<S> observeForCommit(S known) async => current;
  @override
  Future<S> refresh() async {
    if (!observing.isCompleted) observing.complete();
    final pending = refreshReply;
    refreshReply = null;
    if (pending != null) current = await pending.future;
    return current;
  }

  @override
  PreparedCommit<EditSettlement<S>> prepare(EditCapture<S, E> capture) =>
      PreparedCommit(
        id: Object(),
        label: capture.label,
        resources: {key},
        send: () async {
          captures.add(capture);
          if (!started.isCompleted) started.complete();
          final pending = reply;
          reply = null;
          final result = pending == null
              ? SubmissionConfirmed<EditSettlement<S>>(
                  EditConfirmed(accepted(capture.proposed)),
                )
              : await pending.future;
          if (result case SubmissionConfirmed(
            value: EditConfirmed(:final observation),
          )) {
            current = observation;
          }
          return result;
        },
      );
}
