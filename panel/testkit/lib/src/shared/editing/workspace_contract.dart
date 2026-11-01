import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Declares the contract every editing workspace model keeps, as a group
/// named [label]: staged edits, authoritative observations and replies over
/// documents [model] edits, starting from [initial], changed by [change],
/// read back by [read], and settled by the persistence as [accepted].
void editingWorkspaceContract<S, E>(
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
    late ContractPersistence<S, E> boundary;
    late EditingWorkspace<S, E> owner;
    late EditingWorkDriver<S, E> driver;
    late EditGroupId id;
    late EditGroupControl<S, E> control;
    setUp(() {
      session = ScopedWorkSession();
      boundary = ContractPersistence(initial(), accepted);
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
    // A new operation group "Move" holding the accepted edit to "Move".
    EditGroupId stagedMove() {
      final operation = owner.createGroup(
        label: "Move",
        lifetime: EditGroupLifetime.operation,
        policy: EditorCommitPolicy.applyResource,
      );
      owner.stage(operation, change(owner.document, "Move")).requireAccepted();
      return operation;
    }

    test(
      "settled operation groups retire while reusable controls survive",
      () async {
        for (var index = 0; index < 100; index++) {
          final operation = owner.createGroup(
            label: "Move $index",
            lifetime: EditGroupLifetime.operation,
            policy: EditorCommitPolicy.applyResource,
          );
          owner
              .stage(operation, change(owner.document, "Move $index"))
              .requireAccepted();
          await owner.save(operation);
          expect(driver.snapshot.entries, isEmpty);
        }
        stage("Next form edit");
        await control.apply();
        expect(control.canEdit, isTrue);
        expect(owner.submissionId(id), isNotNull);
        expect(read(owner.confirmed), "Next form edit");
      },
    );

    test(
      "a retained operation control pins settled identity until disposed",
      () async {
        final operation = owner.createGroup(
          label: "Move",
          lifetime: EditGroupLifetime.operation,
          policy: EditorCommitPolicy.applyResource,
        );
        final retained = owner.group(operation);
        owner
            .stage(operation, change(owner.document, "Move"))
            .requireAccepted();
        await retained.apply();
        expect(retained.canEdit, isTrue);
        expect(owner.submissionId(operation), isNotNull);
        retained.dispose();
        expect(() => owner.group(operation), throwsStateError);
      },
    );

    test("a rollback hold retains discarded operation identity and restores intent", () {
      final operation = stagedMove();
      final hold = owner.holdStage();
      expect(owner.discard(operation), isTrue);
      owner.retireIdleGroups();
      expect(owner.disposeEmptyGroup(operation), isFalse);
      hold.rollback();
      hold.release();
      expect(read(owner.document), "Move");
      expect(owner.canSave(operation), isTrue);
      owner.discard(operation);
      expect(() => owner.group(operation), throwsStateError);
    });

    test(
      "uncertain operations retain their delivery and recovery identity",
      () async {
        final operation = stagedMove();
        final reply = boundary.reply = Completer();
        final saving = owner.save(operation);
        await boundary.started.future;
        reply.complete(
          SubmissionUncertain(
            message: "Reply lost",
            cause: StateError("Reply lost"),
            stackTrace: StackTrace.current,
          ),
        );
        await saving;
        owner.retireIdleGroups();
        final retained = owner.group(operation);
        expect(retained.state.hasSubmittedWork, isTrue);
        expect(owner.submissionId(operation), isNotNull);
        retained.dispose();
        expect(owner.disposeEmptyGroup(operation), isFalse);
      },
    );

    test("operation identity survives a frozen prefix until its later tail settles", () async {
      final operation = owner.createGroup(
        label: "Move",
        lifetime: EditGroupLifetime.operation,
        policy: EditorCommitPolicy.applyResource,
        admission: EditWriteAdmission.allowWhileSubmitted,
      );
      owner.stage(operation, change(owner.document, "Move")).requireAccepted();
      final reply = boundary.reply = Completer();
      final saving = owner.save(operation);
      await boundary.started.future;
      owner.stage(operation, change(owner.document, "Later")).requireAccepted();
      reply.complete(
        SubmissionConfirmed(
          EditConfirmed(accepted(boundary.captures.single.proposed)),
        ),
      );
      await saving;
      expect(owner.canSave(operation), isTrue);
      expect(read(owner.document), "Later");
      await owner.save(operation);
      expect(() => owner.group(operation), throwsStateError);
      expect(read(owner.confirmed), "Later");
    });

    test(
      "acknowledged operation remains until refresh succeeds then retires",
      () async {
        final operation = stagedMove();
        final reply = boundary.reply = Completer();
        final refresh = boundary.refreshReply = Completer();
        final saving = owner.save(operation);
        await boundary.started.future;
        reply.complete(const SubmissionConfirmed(EditAccepted()));
        await boundary.observing.future;
        refresh.completeError(StateError("Refresh failed"));
        await saving;
        expect(owner.canRetry(operation), isTrue);
        expect(owner.disposeEmptyGroup(operation), isFalse);
        boundary.current = accepted(boundary.captures.single.proposed);
        await owner.retry(operation);
        expect(() => owner.group(operation), throwsStateError);
        expect(read(owner.confirmed), "Move");
      },
    );

    test("group cleanup cannot discard an admitted operation", () {
      stage("Draft");
      expect(owner.disposeEmptyGroup(id), isFalse);
      expect(read(owner.document), "Draft");
      expect(control.state.hasWork, isTrue);
    });

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
        // The saved values stay unread, so the outcome stays unknown.
        boundary.refreshReply = Completer();
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

/// An edit persistence for [editingWorkspaceContract] that controls only
/// authoritative observations and replies.
final class ContractPersistence<S, E> implements EditPersistence<S, E> {
  ContractPersistence(this.current, this.accepted);
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
