import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "Realm operation commands evaluate the captured resource payload",
    () async {
      final document = _document;
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
            payload: skir.ExpressionNode.createInput(
              binding: skir.ExpressionBindingId(value: "context:subject"),
              path: editorRootPath,
            ),
          ),
        ),
      );
      expect(payload, skir.DataValue.wrapStringValue(_first.value));
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
      final document = _document;
      final input = OperationInputDraft(
        catalog: document.catalog,
        type: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
        value: skir.DataValue.wrapStringValue("First"),
      );
      addTearDown(input.dispose);
      final submitted = input.revision;
      expect(
        input.write(editorRootPath, skir.DataValue.wrapStringValue("Second")),
        isA<PortablePresentationWriteApplied>(),
      );
      expect(
        input.normalize(
          skir.DataValue.wrapStringValue("Old reply"),
          submittedRevision: submitted,
        ),
        isFalse,
      );
      expect(input.value, skir.DataValue.wrapStringValue("Second"));
      expect(
        document.resource(_first)!.authoredField("title"),
        skir.DataValue.wrapStringValue("Saved"),
      );
    },
  );

  test("transient input host refuses wrong types and closed writes", () async {
    final input = OperationInputDraft(
      catalog: _document.catalog,
      type: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
      value: skir.DataValue.wrapStringValue("First"),
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
      await host.write(
        reference,
        skir.DataValue.wrapStringValue("Late"),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    host.dispose();
  });

  test(
    "paired capture sends every working difference against its saved token",
    () async {
      final world = await signedInWorld(_heldLibrary);
      final workspace = await world.openRealmEditing();
      workspace.form(_first).setText("Rename", _firstTitle, "Visible draft");
      final capture = workspace.captureOperationContext();
      expect(
        capture.context.confirmedObservation,
        world.requireRealm.document.confirmedObservation,
      );
      expect(capture.context.overlay.upserts.map((entry) => entry.resource), [
        _first,
      ]);
      expect(
        capture.context.overlay.upserts.single.content.authoredField("title"),
        skir.DataValue.wrapStringValue("Visible draft"),
      );
      expect(capture.context.overlay.removals, isEmpty);
      expect(capture.document, same(workspace.document));
    },
  );

  test(
    "paired capture includes removed resources and newly created resources",
    () async {
      final workspace = await (await signedInWorld(_heldLibrary))
          .openRealmEditing();
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
      // The Library lists the removed Book no longer, so it changed too.
      expect(
        capture.context.overlay.upserts.map((entry) => entry.resource),
        unorderedEquals([libraryId, skir.ResourceId(value: "copy")]),
      );
    },
  );

  test("a remote edit over a draft saves against the saved title and is "
      "refused once that title changed", () async {
    final world = await signedInWorld(_heldLibrary);
    final seeded = world.requireRealm;
    final workspace = await world.openRealmEditing();
    workspace.form(_first).setText("Rename", _firstTitle, "Draft");
    final remote = AuthoringEdit.fromDocument(
      workspace.captureOperationContext().document,
    )..set(_firstTitle, skir.DataValue.wrapStringValue("Prefix Draft"));
    final (group: operation, :staged) = workspace.stageRequired(
      "Prefix",
      remote,
    );
    expect(staged, isA<EditStaged>());
    final saving = workspace.save(operation);
    await Future<void>.delayed(Duration.zero);
    expect(seeded.saves, hasLength(1));
    final expectations = seeded.saves.single.edit.expectations;
    expect(seeded.document.facts.conflicts(expectations), isEmpty);
    expect(
      seeded.document
          .changedRemotely(
            (edit) => edit.set(
              _firstTitle,
              skir.DataValue.wrapStringValue("Renamed elsewhere"),
            ),
          )
          .facts
          .conflicts(expectations),
      isNotEmpty,
    );
    seeded.saves.single.confirm();
    await saving;
    expect(
      workspace.captureOperationContext().context.overlay.upserts,
      isEmpty,
    );
  });

  test("atomic dependency composition preserves unrelated work and later form edits", () async {
    final world = await signedInWorld(_heldLibrary);
    final seeded = world.requireRealm;
    final workspace = await world.openRealmEditing();
    final form = workspace.form(_first)
      ..setText("Required rename", _firstTitle, "Draft")
      ..setText(
        "Unrelated rename",
        authoredFieldLocation(_second, ["title"]),
        "Unrelated",
      );
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..set(_firstTitle, skir.DataValue.wrapStringValue("Prefix Draft"));
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
    final saving = workspace.save(operation);
    await Future<void>.delayed(Duration.zero);
    expect(seeded.saves, hasLength(1));
    form.setText("Later name", _firstTitle, "Later").requireAccepted();
    seeded.saves.single.confirm();
    await saving;
    expect(
      seeded.document.resource(_first)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Prefix Draft"),
    );
    expect(
      seeded.document.resource(_second)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Saved"),
    );
    expect(
      workspace.document.resource(_first)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Later"),
    );
    expect(
      workspace.document.resource(_second)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Unrelated"),
    );
    expect(
      workspace.workspace.confirmed.resource(_second)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Saved"),
    );
    expect(workspace.state.groups.containsKey(operation), isFalse);
    expect(form.dirty, isTrue);
  });

  test("a conflicted required draft rejects atomic admission without taking its work", () async {
    final world = await signedInWorld(_heldLibrary);
    final seeded = world.requireRealm;
    final workspace = await world.openRealmEditing();
    workspace.form(_first).setText("Draft", _firstTitle, "Draft");
    seeded.remoteChange(
      (edit) =>
          edit.set(_firstTitle, skir.DataValue.wrapStringValue("External")),
    );
    await workspace.eventually(
      () => workspace.workspace.confirmed.resource(_first)!.authoredField(
        "title",
      ),
      (title) => title == skir.DataValue.wrapStringValue("External"),
      description: "the external title admitted",
    );
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..set(_firstTitle, skir.DataValue.wrapStringValue("Prefix Draft"));
    final (group: operation, :staged) = workspace.stageRequired(
      "Prefix",
      remote,
    );
    expect(staged, isA<EditStageRejected>());
    expect(
      workspace.document.resource(_first)!.authoredField("title"),
      skir.DataValue.wrapStringValue("Draft"),
    );
    expect(workspace.disposeEmptyGroup(operation), isTrue);
  });

  test(
    "submitted required drafts cannot be absorbed into a second submission",
    () async {
      final world = await signedInWorld(_heldLibrary);
      final seeded = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_first)
        ..setText("Draft", _firstTitle, "Draft");
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      final remote = AuthoringEdit.fromDocument(workspace.document)
        ..set(_firstTitle, skir.DataValue.wrapStringValue("Prefix Draft"));
      final (group: operation, :staged) = workspace.stageRequired(
        "Prefix",
        remote,
      );
      expect(staged, isA<EditStageRejected>());
      expect(seeded.saves, hasLength(1));
      seeded.saves.single.loseReply(StateError("Unknown delivery"));
      await saving;
      expect(form.phase, isA<EditGroupUncertain>());
      expect(
        workspace.document.resource(_first)!.authoredField("title"),
        skir.DataValue.wrapStringValue("Draft"),
      );
      expect(workspace.disposeEmptyGroup(operation), isTrue);
    },
  );

  test("changed facts reject an entire prepared deletion without selection effects", () async {
    final world = await signedInWorld(_heldLibrary);
    final workspace = await world.openRealmEditing();
    final scope = world.requireRealm.scope;
    final selected = [AuthoringResourceIdentifier.inScope(scope, _first)];
    world.container.read(selectionProvider.notifier).selectAll(selected);
    final remote = AuthoringEdit.fromDocument(workspace.document)
      ..delete(_first)
      ..delete(_second);
    workspace
        .form(_second)
        .setText(
          "Concurrent draft",
          authoredFieldLocation(_second, ["title"]),
          "Changed",
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
    expect(world.container.read(selectionProvider), selected);
    expect(workspace.disposeEmptyGroup(group), isTrue);
  });

  test(
    "resource action targets remain those captured before selection changed",
    () async {
      final world = await signedInWorld(_heldLibrary);
      final scope = world.requireRealm.scope;
      final selection = world.container.read(selectionProvider.notifier)
        ..selectAll([AuthoringResourceIdentifier.inScope(scope, _first)]);
      final document = world.requireRealm.document;
      final captured = resourceActionContext(document, [_first]);
      selection.selectAll([
        AuthoringResourceIdentifier.inScope(scope, _second),
      ]);
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
          targets: skir.ExpressionNode.createInput(
            binding: skir.ExpressionBindingId(value: "context:selection"),
            path: editorRootPath,
          ),
          initialInput: null,
        ),
      );
      expect(invoked, [_first]);
    },
  );

  test(
    "expired action lifetime prevents both navigation and preparation",
    () async {
      var effects = 0;
      final document = _document;
      final dispatcher = ResourceActionDispatcher(
        catalog: document.catalog,
        context: resourceActionContext(document, [_first]),
        isCurrent: () => false,
        navigate: (_, _) async => effects++,
        prepare: (_, _, _) async => effects++,
      );
      await dispatcher.dispatch(
        skir.EditorAction.createNavigate(
          resource: skir.ExpressionNode.createInput(
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
final _books = [
  for (final id in [_first, _second])
    Book(bookId: id, title: "Saved", icon: "mdi:book", color: Colors.blue),
];

/// The saved document of the Realm holding both Books.
final _document = realmDocument(books: _books);

/// The title of the [_first] Book.
final _firstTitle = authoredFieldLocation(_first, ["title"]);

/// Ada in Acme, whose Realm holds [_books] and holds every save until the
/// test answers it.
final _heldLibrary = [
  signedIn(ada, organization: acme),
  realm(books: _books),
  heldSaves,
];
