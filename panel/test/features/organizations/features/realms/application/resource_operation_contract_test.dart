import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "Realm operation commands evaluate the captured resource payload",
    () async {
      final document = _document();
      skir.DataValue? payload;
      final capability = skir.CapabilityId(value: "fixture:command");
      final dispatcher = ResourceActionDispatcher(
        catalog: document.catalog,
        context: resourceActionContext(document, [_first]),
        isCurrent: () => true,
        navigate: (_, _) async {},
        prepare: (_, _, _) async {},
        invokeCommand: (id, value) async {
          expect(id, capability);
          payload = value;
        },
      );
      await dispatcher.dispatch(
        skir.EditorAction.wrapRealm(
          skir.RealmEditorAction.createCommand(
            capabilityId: capability,
            payload: skir.ExpressionNode.createRead(
              binding: skir.ExpressionBindingId(value: "context:subject"),
              path: editorRootPath,
            ),
          ),
        ),
      );
      expect(payload, _text(_first.value));
    },
  );

  test(
    "Realm command instructions stop when their invoking view expires",
    () async {
      var current = true;
      final statuses = <String>[];
      await handleRealmCommandResult(
        skir.CommandResult.createSuccess(
          invocationId: skir.InvocationId(value: "fixture:command"),
          instructions: [
            skir.PanelInstruction.createNotify(
              message: "Before",
              severity: skir.NotificationSeverity.info,
            ),
            skir.PanelInstruction.createNotify(
              message: "After",
              severity: skir.NotificationSeverity.info,
            ),
          ],
        ),
        isCurrent: () => current,
        reload: () async {},
        openResource: (_) {},
        reportStatus: (message) {
          statuses.add(message);
          current = false;
        },
      );
      expect(statuses, ["Before"]);
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "operation input rejects stale normalization and never stages a resource",
    () {
      final document = _document();
      final input = OperationInputDraft(
        catalog: document.catalog,
        type: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        value: _text("First"),
      );
      addTearDown(input.dispose);
      final submitted = input.revision;
      expect(
        input.write(editorRootPath, _text("Second")),
        isA<PortablePresentationWriteApplied>(),
      );
      expect(
        input.normalize(_text("Old reply"), submittedRevision: submitted),
        isFalse,
      );
      expect(input.value, _text("Second"));
      expect(document.resource(_first)!.authoredField("title"), _text("Saved"));
    },
  );

  test("transient input host refuses wrong types and closed writes", () async {
    final input = OperationInputDraft(
      catalog: _document().catalog,
      type: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      value: _text("First"),
    );
    final host = input.createHost();
    final reference = skir.BindingRef(
      bindingId: configuredValueBindingId,
      path: editorRootPath,
    );
    expect(
      await host.write(
        reference,
        skir.DataValue.wrapBoolean(true),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    input.dispose();
    expect(
      await host.write(reference, _text("Late"), context: host.rootInvocation),
      isA<PortablePresentationWriteRejected>(),
    );
    host.dispose();
  });

  test(
    "paired capture sends every working difference against its saved token",
    () {
      final workspace = _workspace(_document());
      final draft = workspace.attach(
        _first,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(draft.detach);
      draft.edit(
        label: "Rename",
        apply: (edit) => edit.set(_title(_first), _text("Visible draft")),
      );
      final capture = workspace.captureOperationContext();
      expect(
        capture.context.confirmedObservation,
        skir.AuthoringObservationId(value: "saved:1"),
      );
      expect(capture.context.overlay.upserts.map((entry) => entry.resource), [
        _first,
      ]);
      expect(
        capture.context.overlay.upserts.single.content.authoredField("title"),
        _text("Visible draft"),
      );
      expect(capture.context.overlay.removals, isEmpty);
      expect(capture.document, same(workspace.document));
    },
  );

  test(
    "paired capture includes removed resources and newly created resources",
    () {
      final workspace = _workspace(_document());
      final group = workspace.workspace.createGroup(
        label: "Draft",
        policy: EditorCommitPolicy.applyResource,
      );
      workspace
          .edit(
            group: group,
            label: "Draft",
            apply: (edit) {
              edit
                ..delete(_second)
                ..create(
                  skir.ResourceId(value: "copy"),
                  workspace.document.resource(_first)!,
                );
            },
          )
          .requireAccepted();
      final capture = workspace.captureOperationContext();
      expect(capture.context.overlay.removals, [_second]);
      expect(capture.context.overlay.upserts.map((entry) => entry.resource), [
        skir.ResourceId(value: "copy"),
      ]);
    },
  );

  test(
    "a remote edit reads a draft and composes its saved witness once",
    () async {
      final transport = ScriptedAuthoringTransport(AsyncData(_document()));
      final workspace = _workspace(
        transport.observation.requireValue,
        transport: transport,
      );
      final form = workspace.attach(
        _first,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Rename",
        apply: (edit) => edit.set(_title(_first), _text("Draft")),
      );
      final remote = AuthoringEdit.fromDocument(
        workspace.captureOperationContext().document,
      )..set(_title(_first), _text("Prefix Draft"));
      final operation = workspace.workspace.createGroup(
        label: "Prefix",
        policy: EditorCommitPolicy.applyResource,
        commits: EditCommitAdmission.requiredDependencies,
      );
      expect(
        workspace.stagePrepared(
          group: operation,
          label: "Prefix",
          edit: remote.prepare(),
        ),
        isA<EditStaged>(),
      );
      final saving = workspace.save(operation);
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests, hasLength(1));
      final witnessed = transport.requests.single.edit.expectations
          .whereType<skir.EditExpectation_valueWrapper>()
          .where((entry) => entry.value.at == _title(_first))
          .single
          .value
          .expected;
      expect(witnessed, _text("Saved"));
      transport.confirm(
        0,
        workspace.document.copyWith(
          confirmedObservation: skir.AuthoringObservationId(value: "saved:2"),
        ),
      );
      await saving;
      expect(
        workspace.captureOperationContext().context.overlay.upserts,
        isEmpty,
      );
    },
  );

  test("atomic dependency composition preserves unrelated work and later form edits", () async {
    final initial = _document();
    final transport = ScriptedAuthoringTransport(AsyncData(initial));
    final workspace = _workspace(initial, transport: transport);
    final form = workspace.attach(
      _first,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form
      ..edit(
        label: "Required rename",
        apply: (edit) => edit.set(_title(_first), _text("Draft")),
      )
      ..edit(
        label: "Unrelated rename",
        apply: (edit) => edit.set(_title(_second), _text("Unrelated")),
      );
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..set(_title(_first), _text("Prefix Draft"));
    final operation = workspace.workspace.createGroup(
      label: "Prefix",
      policy: EditorCommitPolicy.applyResource,
      commits: EditCommitAdmission.requiredDependencies,
    );
    workspace
        .stagePrepared(
          group: operation,
          label: "Prefix",
          edit: remote.prepare(),
        )
        .requireAccepted();
    expect(form.dirty, isTrue);
    expect(workspace.state.groups[operation]!.operationCount, 2);
    expect(workspace.state.groups[form.editingGroup]!.operationCount, 1);
    final saving = workspace.save(operation);
    await Future<void>.delayed(Duration.zero);
    expect(transport.requests, hasLength(1));
    expect(
      transport.requests.single.edit.intents
          .whereType<skir.EditIntent_setValueWrapper>()
          .map((intent) => intent.value.at.resource)
          .toSet(),
      {_first},
    );
    form
        .edit(
          label: "Later name",
          apply: (edit) => edit.set(_title(_first), _text("Later")),
        )
        .requireAccepted();
    final committed = AuthoringEdit.fromDocument(initial)
      ..set(_title(_first), _text("Prefix Draft"));
    transport.confirm(
      0,
      committed.toDocument().copyWith(
        confirmedObservation: skir.AuthoringObservationId(value: "saved:2"),
      ),
    );
    await saving;
    expect(
      workspace.document.resource(_first)!.authoredField("title"),
      _text("Later"),
    );
    expect(
      workspace.document.resource(_second)!.authoredField("title"),
      _text("Unrelated"),
    );
    expect(
      workspace.workspace.confirmed.resource(_second)!.authoredField("title"),
      _text("Saved"),
    );
    expect(workspace.state.groups.containsKey(operation), isFalse);
    expect(form.dirty, isTrue);
  });

  test("a conflicted required draft rejects atomic admission without taking its work", () {
    final initial = _document();
    final workspace = _workspace(initial);
    final form = workspace.attach(
      _first,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form.edit(
      label: "Draft",
      apply: (edit) => edit.set(_title(_first), _text("Draft")),
    );
    final external = AuthoringEdit.fromDocument(initial)
      ..set(_title(_first), _text("External"));
    workspace.acceptConfirmed(
      external.toDocument().copyWith(
        confirmedObservation: skir.AuthoringObservationId(value: "saved:2"),
      ),
    );
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..set(_title(_first), _text("Prefix Draft"));
    final operation = workspace.workspace.createGroup(
      label: "Prefix",
      policy: EditorCommitPolicy.applyResource,
      commits: EditCommitAdmission.requiredDependencies,
    );
    expect(
      workspace.stagePrepared(
        group: operation,
        label: "Prefix",
        edit: remote.prepare(),
      ),
      isA<EditStageRejected>(),
    );
    expect(workspace.state.groups[form.editingGroup]!.operationCount, 1);
    expect(
      workspace.document.resource(_first)!.authoredField("title"),
      _text("Draft"),
    );
    expect(workspace.disposeEmptyGroup(operation), isTrue);
  });

  test(
    "submitted required drafts cannot be absorbed into a second submission",
    () async {
      final initial = _document();
      final transport = ScriptedAuthoringTransport(AsyncData(initial));
      final workspace = _workspace(initial, transport: transport);
      final form = workspace.attach(
        _first,
        policy: EditorCommitPolicy.applyResource,
      );
      addTearDown(form.detach);
      form.edit(
        label: "Draft",
        apply: (edit) => edit.set(_title(_first), _text("Draft")),
      );
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      final remote = AuthoringEdit.fromDocument(workspace.document)
        ..set(_title(_first), _text("Prefix Draft"));
      final operation = workspace.workspace.createGroup(
        label: "Prefix",
        policy: EditorCommitPolicy.applyResource,
        commits: EditCommitAdmission.requiredDependencies,
      );
      expect(
        workspace.stagePrepared(
          group: operation,
          label: "Prefix",
          edit: remote.prepare(),
        ),
        isA<EditStageRejected>(),
      );
      expect(transport.requests, hasLength(1));
      transport.loseReply(0, StateError("Unknown delivery"));
      await saving;
      expect(form.phase, isA<EditGroupUncertain>());
      expect(
        workspace.document.resource(_first)!.authoredField("title"),
        _text("Draft"),
      );
      expect(workspace.disposeEmptyGroup(operation), isTrue);
    },
  );

  test("changed facts reject an entire prepared deletion without selection effects", () {
    final workspace = _workspace(_document());
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..delete(_first)
      ..delete(_second);
    final form = workspace.attach(
      _second,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(form.detach);
    form.edit(
      label: "Concurrent draft",
      apply: (edit) => edit.set(_title(_second), _text("Changed")),
    );
    final group = workspace.workspace.createGroup(
      label: "Delete",
      policy: EditorCommitPolicy.applyResource,
    );
    expect(
      workspace.stagePrepared(
        group: group,
        label: "Delete",
        edit: remote.prepare(),
      ),
      isA<EditStageRejected>(),
    );
    expect(workspace.document.entry(_first), isNotNull);
    expect(workspace.document.entry(_second), isNotNull);
    expect(workspace.disposeEmptyGroup(group), isTrue);
  });

  test(
    "resource action targets remain those captured before selection changed",
    () async {
      final document = _document();
      final captured = resourceActionContext(document, [_first]);
      var globalSelection = [_first];
      globalSelection = [_second];
      List<skir.ResourceId>? invoked;
      final dispatcher = ResourceActionDispatcher(
        catalog: document.catalog,
        context: captured,
        isCurrent: () => true,
        navigate: (_, _) async {},
        prepare: (_, targets, _) async => invoked = targets,
      );
      await dispatcher.dispatch(
        skir.EditorAction.createAuthoring(
          capability: skir.CapabilityId(value: "fixture:prefix"),
          targets: skir.ExpressionNode.createRead(
            binding: skir.ExpressionBindingId(value: "context:selection"),
            path: editorRootPath,
          ),
          initialInput: null,
        ),
      );
      expect(globalSelection, [_second]);
      expect(invoked, [_first]);
    },
  );

  test(
    "expired action lifetime prevents both navigation and preparation",
    () async {
      var effects = 0;
      final document = _document();
      final dispatcher = ResourceActionDispatcher(
        catalog: document.catalog,
        context: resourceActionContext(document, [_first]),
        isCurrent: () => false,
        navigate: (_, _) async => effects++,
        prepare: (_, _, _) async => effects++,
      );
      await dispatcher.dispatch(
        skir.EditorAction.createNavigate(
          resource: skir.ExpressionNode.createRead(
            binding: skir.ExpressionBindingId(value: "context:subject"),
            path: editorRootPath,
          ),
          mode: skir.ResourceNavigationMode.open,
        ),
      );
      expect(effects, 0);
    },
  );
}

final _first = skir.ResourceId(value: "book:first");
final _second = skir.ResourceId(value: "book:second");
skir.DataValue _text(String value) => skir.DataValue.wrapStringValue(value);
skir.ValueLocation _title(skir.ResourceId id) =>
    authoredFieldLocation(id, ["title"]);
AuthoringDocument _document() => fixtureAuthoringDocument(
  books: [
    for (final id in [_first, _second])
      Book(
        bookId: id,
        title: "Saved",
        icon: "mdi:book",
        color: Colors.blue,
        tagIds: const [],
      ),
  ],
).copyWith(confirmedObservation: skir.AuthoringObservationId(value: "saved:1"));

RealmEditing _workspace(
  AuthoringDocument document, {
  ScriptedAuthoringTransport? transport,
}) {
  final session = ScopedWorkSession();
  final source = transport ?? ScriptedAuthoringTransport(AsyncData(document));
  final workspace = RealmEditing(
    persistence: source.persistence,
    submissions: session,
    initial: document,
  );
  addTearDown(workspace.dispose);
  addTearDown(session.dispose);
  addTearDown(source.dispose);
  return workspace;
}
