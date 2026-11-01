import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The saved record [_resource] named "Original" at position 0.
final _saved = authoredDoc([
  authoredRecord(_resource, texts({"name": "Original", "position": "0"})),
]).document;

/// Ada in Acme, whose Realm holds [_saved].
final _original = adaServing(_saved);

void main() {
  test(
    "review observation failure preserves the journal and sends no request",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource)..setText("Name", _name, "Local");
      realm
        ..refreshFailure = StateError("Offline")
        ..remoteChange(
          (edit) => edit.set(_name, skir.DataValue.wrapStringValue("Remote")),
        );
      await world.container.pump();
      expect(form.phase, isA<EditGroupConflict<AuthoringDocument>>());
      await expectLater(
        editing.refreshedConflictReview(form.editingGroup),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            "message",
            "Offline",
          ),
        ),
      );
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(realm.saves, isEmpty);
      expect(editing.state.groups, hasLength(1));
    },
  );

  test("replacement cannot discard a submitted or uncertain prefix", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final editing = await world.openRealmEditing();
    final form = editing.form(_resource)..setText("Name", _name, "Local");
    final review = editing.workspace.inspectUnsubmitted(form.editingGroup);
    final saving = form.save();
    await Future<void>.delayed(Duration.zero);
    expect(
      editing.workspace.replaceUnsubmitted(
        form.editingGroup,
        expectedOperations: review.operations,
        expectedEdits: review.edits,
      ),
      isA<EditStageRejected>(),
    );
    realm.saves.last.loseReply(StateError("Reply lost"));
    await saving;
    expect(
      editing.workspace.replaceUnsubmitted(
        form.editingGroup,
        expectedOperations: review.operations,
        expectedEdits: review.edits,
      ),
      isA<EditStageRejected>(),
    );
    expect(form.phase, isA<EditGroupUncertain>());
    expect(realm.saves, hasLength(1));
  });

  test(
    "a removed stable collection item cannot be forced by Keep mine",
    () async {
      final itemsAt = authoredFieldLocation(_resource, ["items"]);
      final stable = skir.ItemId(value: "stable");
      final other = skir.ItemId(value: "other");
      final initial =
          AuthoringEdit.fromDocument(
            authoredDoc([
              authoredRecord(
                _resource,
                texts({"name": "Original", "position": "0"}),
              ),
            ]).document,
          )..set(
            itemsAt,
            skir.DataValue.createListValue(
              items: [
                skir.ListItem(
                  id: stable,
                  value: skir.DataValue.wrapStringValue("Initial"),
                ),
                skir.ListItem(
                  id: other,
                  value: skir.DataValue.wrapStringValue("Other"),
                ),
              ],
            ),
          );
      final world = testWorld([...adaServing(initial.toDocument()), heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource);
      form
          .edit(
            label: "Move item",
            apply: (edit) => edit.move(itemsAt, stable, other),
          )
          .requireAccepted();
      final removed = AuthoringEdit.fromDocument(realm.document)
        ..set(
          itemsAt,
          skir.DataValue.createListValue(
            items: [
              skir.ListItem(
                id: other,
                value: skir.DataValue.wrapStringValue("Other"),
              ),
            ],
          ),
        );
      realm.serve(removed.toDocument());
      await world.container.pump();

      expect(form.phase, isA<EditGroupRejected<AuthoringDocument>>());
      expect(editing.conflictReview(form.editingGroup), isNull);
      expect(realm.saves, isEmpty);
      expect(form.discard(), isTrue);
      expect(editing.state.groups, isEmpty);
      expect(
        editing.document.valueAt(itemsAt),
        realm.document.valueAt(itemsAt),
      );
    },
  );

  test("removed resources retain the complete group proposal", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final editing = await world.openRealmEditing();
    final form = editing.form(_resource)
      ..setText("Name", _name, "Local").requireAccepted()
      ..setText("Position", _position, "Local position").requireAccepted();
    realm.serve(realm.document.copyWith(entries: {}));
    final review = await editing.refreshedConflictReview(form.editingGroup);
    expect(review.canKeepMine, isFalse);
    expect(
      review.proposal.valueAt(_name),
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(
      review.proposal.valueAt(_position),
      skir.DataValue.wrapStringValue("Local position"),
    );
    editing
        .resolveConflict(review, AuthoringConflictChoice.useSaved)
        .requireAccepted();
    expect(editing.state.groups, isEmpty);
    expect(realm.saves, isEmpty);
  });

  test(
    "invalid replacement publishes nothing and preserves peer proposals",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource)
        ..setText("Name", _name, "Local").requireAccepted();
      final peer = editing.setText(
        "Peer",
        _position,
        "Peer",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      final reviewed = editing.workspace.inspectUnsubmitted(form.editingGroup);
      final stale = AuthoringEdit.fromDocument(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Obsolete", "position": "0"}),
          ),
        ]).document,
      )..set(_name, skir.DataValue.wrapStringValue("Replacement"));
      var notifications = 0;
      editing.addListener(() => notifications++);
      expect(
        editing.workspace.replaceUnsubmitted(
          form.editingGroup,
          expectedOperations: reviewed.operations,
          expectedEdits: reviewed.edits,
          replacement: stale.capture(),
        ),
        isA<EditStageRejected>(),
      );
      expect(notifications, 0);
      expect(
        editing.workspace.inspectUnsubmitted(form.editingGroup).edits,
        reviewed.edits,
      );
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(
        editing.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Peer"),
      );
      final deletion = AuthoringEdit.fromDocument(reviewed.beforeGroup)
        ..delete(_resource);
      editing.workspace
          .replaceUnsubmitted(
            form.editingGroup,
            expectedOperations: reviewed.operations,
            expectedEdits: reviewed.edits,
            replacement: deletion.capture(),
          )
          .requireAccepted();
      final peerReview = editing.workspace.inspectUnsubmitted(peer.group);
      expect(
        peerReview.proposal.valueAt(_position),
        skir.DataValue.wrapStringValue("Peer"),
      );
      expect(peerReview.diagnostics, isNotEmpty);
      expect(realm.saves, isEmpty);
    },
  );

  test("replacement rejects a new group dependency cycle atomically", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final editing = await world.openRealmEditing();
    final peer = editing.setText(
      "Peer starts",
      _name,
      "Peer first",
      policy: EditorCommitPolicy.applyResource,
    ) as EditStaged;
    final selected = editing.setText(
      "Position",
      _position,
      "Local",
      policy: EditorCommitPolicy.applyResource,
    ) as EditStaged;
    editing
        .edit(
          group: peer.group,
          label: "Peer depends on position",
          apply: (edit) {
            edit
              ..applyPrepared(
                skir.PreparedEdit(
                  catalog: editing.document.generation,
                  expectations: [textExpectation(_position, "Local")],
                  intents: const [],
                ),
              )
              ..set(_name, skir.DataValue.wrapStringValue("Peer final"));
          },
        )
        .requireAccepted();
    final reviewed = editing.workspace.inspectUnsubmitted(selected.group);
    final replacement = AuthoringEdit.fromDocument(reviewed.beforeGroup)
      ..applyPrepared(
        skir.PreparedEdit(
          catalog: reviewed.beforeGroup.generation,
          expectations: [textExpectation(_name, "Peer first")],
          intents: const [],
        ),
      )
      ..set(_position, skir.DataValue.wrapStringValue("Replacement"));
    var notifications = 0;
    editing.addListener(() => notifications++);
    final result = editing.workspace.replaceUnsubmitted(
      selected.group,
      expectedOperations: reviewed.operations,
      expectedEdits: reviewed.edits,
      replacement: replacement.capture(),
    );
    expect(result, isA<EditStageRejected>());
    expect((result as EditStageRejected).message, contains("dependency cycle"));
    expect(notifications, 0);
    expect(
      editing.workspace.inspectUnsubmitted(selected.group).edits,
      reviewed.edits,
    );
    expect(
      editing.document.valueAt(_position),
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(
      editing.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Peer final"),
    );
    expect(editing.state.groups, hasLength(2));
    expect(realm.saves, isEmpty);
  });

  test("an imported edit saves against the original saved content and is "
      "refused once that content changed", () {
    final saved = _saved;
    final nameChange = AuthoringEdit.fromDocument(saved)
      ..set(_name, skir.DataValue.wrapStringValue("First"));
    final preceding = nameChange.toDocument();
    final facts = [
      textExpectation(_name, "First"),
      skir.EditExpectation.createResource(
        id: _resource,
        expected: preceding.resource(_resource),
      ),
      skir.EditExpectation.createResourceExists(id: _resource, expected: true),
      skir.EditExpectation.createConfiguration(
        at: skir.ValueLocation(resource: _resource, path: editorRootPath),
        expected: preceding.resource(_resource)!.configuration,
      ),
      skir.EditExpectation.wrapResourceIds(preceding.entries.keys.toList()),
      skir.EditExpectation.createLinks(
        resource: _resource,
        contract: skir.RelationId(value: "relation"),
        direction: skir.TraversalDirection.both,
        expected: const [],
      ),
    ];
    final combined = AuthoringEdit.fromDocument(saved)
      ..applyPrepared(nameChange.prepare())
      ..applyPrepared(
        preparedEdit(
          saved,
          expects: facts,
          intents: [setTextIntent(_position, "2")],
        ),
      );
    expect(
      combined,
      refusedAfter(
        (remote) => remote.set(_name, skir.DataValue.wrapStringValue("Remote")),
        saved: saved,
      ),
    );
    expect(
      combined,
      refusedAfter((remote) => remote.delete(_resource), saved: saved),
    );
  });

  test("an import that read stale content is refused and leaves the draft "
      "unchanged", () {
    final saved = _saved;
    final branch = AuthoringEdit.fromDocument(saved);
    expect(
      () => branch.applyPrepared(
        preparedEdit(
          saved,
          expects: [textExpectation(_name, "Wrong")],
          intents: [setTextIntent(_name, "Local")],
        ),
      ),
      throwsA(isA<AuthoringCompositionFailure>()),
    );
    expect(branch.toDocument().hasSameAuthoredContent(saved), isTrue);
  });

  test("an import whose later intent is invalid rolls back its earlier "
      "intents", () {
    final saved = _saved;
    final branch = AuthoringEdit.fromDocument(saved);
    expect(
      () => branch.applyPrepared(
        preparedEdit(
          saved,
          expects: [textExpectation(_name, "Original")],
          intents: [
            setTextIntent(_name, "Local"),
            setTextIntent(
              authoredFieldLocation(skir.ResourceId(value: "absent"), ["name"]),
              "Bad",
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    expect(branch.toDocument().hasSameAuthoredContent(saved), isTrue);
  });

  test("a created then renamed resource saves as new and is refused once the "
      "id exists", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final editing = await world.openRealmEditing();
    final created = skir.ResourceId(value: "new-resource");
    final at = authoredFieldLocation(created, ["name"]);
    final first = editing.edit(
      label: "Create",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) => edit.create(
        created,
        skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("Initial"),
            ),
          ],
        ),
      ),
    ) as EditStaged;
    editing.edit(
      label: "Rename created",
      group: first.group,
      apply: (edit) => edit.set(at, skir.DataValue.wrapStringValue("Final")),
    );
    final saving = editing.save(first.group);
    await Future<void>.delayed(Duration.zero);
    final request = realm.saves.single.edit;
    expect(realm.document.facts.conflicts(request.expectations), isEmpty);
    final taken = realm.document.changedRemotely(
      (remote) => remote.create(
        created,
        skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("Taken"),
            ),
          ],
        ),
      ),
    );
    expect(taken.facts.conflicts(request.expectations), isNotEmpty);
    realm.saves.single.confirm();
    await saving;
    expect(editing.state.groups, isEmpty);
    expect(realm.document.valueAt(at), skir.DataValue.wrapStringValue("Final"));
  });

  test(
    "Keep mine rewrites the whole group against reviewed saved facts",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource)
        ..setText("Name", _name, "Local")
        ..setText("Position", _position, "Local position");
      realm.serve(
        authoredDoc([
          authoredRecord(_resource, texts({"name": "Remote", "position": "0"})),
        ]).document,
      );
      final review = await editing.refreshedConflictReview(form.editingGroup);
      expect(
        editing.resolveConflict(review, AuthoringConflictChoice.keepMine),
        isA<EditStaged>(),
      );
      expect(form.blocked, isFalse);
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(
        editing.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Local position"),
      );
      expect(realm.saves, isEmpty);
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      expect(
        realm.document.facts.conflicts(realm.saves.single.edit.expectations),
        isEmpty,
      );
      realm.saves.last.confirm(saved: editing.document);
      await saving;
      expect(editing.state.groups, isEmpty);
    },
  );

  test(
    "Use saved removes the selected group and retains independent work",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource)..setText("Name", _name, "Local");
      final peer = editing.setText(
        "Position",
        _position,
        "Peer",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      realm.serve(
        authoredDoc([
          authoredRecord(_resource, texts({"name": "Remote", "position": "0"})),
        ]).document,
      );
      final review = await editing.refreshedConflictReview(form.editingGroup);
      editing
          .resolveConflict(review, AuthoringConflictChoice.useSaved)
          .requireAccepted();
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Remote"),
      );
      expect(
        editing.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Peer"),
      );
      expect(editing.state.groups.keys, [peer.group]);
      expect(realm.saves, isEmpty);
    },
  );

  test(
    "changed saved facts and changed proposals invalidate a review",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource)..setText("Name", _name, "Local");
      realm.serve(
        authoredDoc([
          authoredRecord(_resource, texts({"name": "Remote", "position": "0"})),
        ]).document,
      );
      final review = await editing.refreshedConflictReview(form.editingGroup);
      editing.acceptConfirmed(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Changed again", "position": "0"}),
          ),
        ]).document,
      );
      for (final choice in AuthoringConflictChoice.values) {
        expect(
          editing.resolveConflict(review, choice),
          isA<EditStageRejected>(),
        );
      }
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      final snapshot = editing.workspace.inspectUnsubmitted(form.editingGroup);
      final updated = AuthoringEdit.fromDocument(snapshot.beforeGroup)
        ..set(_name, skir.DataValue.wrapStringValue("New local"));
      editing.workspace
          .replaceUnsubmitted(
            form.editingGroup,
            expectedOperations: snapshot.operations,
            expectedEdits: snapshot.edits,
            replacement: updated.capture(),
          )
          .requireAccepted();
      expect(
        editing.resolveConflict(review, AuthoringConflictChoice.useSaved),
        isA<EditStageRejected>(),
      );
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("New local"),
      );
    },
  );

  test("a save the Realm refuses for changed name and position offers both "
      "for comparison", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final editing = await world.openRealmEditing();
    final form = editing.form(_resource)
      ..setText("Name", _name, "Local")
      ..setText("Position", _position, "Local position");
    final saving = form.save();
    await Future<void>.delayed(Duration.zero);
    realm.serve(
      authoredDoc([
        authoredRecord(
          _resource,
          texts({"name": "Saved", "position": "Saved"}),
        ),
      ]).document,
    );
    realm.saves.single.reject(
      skir.CommitPreparedEditResponse.wrapConflictError([
        for (final (at, before) in [(_name, "Original"), (_position, "0")])
          skir.ExpectationConflict(
            expected: skir.EditExpectation.createValue(
              at: at,
              expected: skir.DataValue.wrapStringValue(before),
            ),
            actual: textExpectation(at, "Saved"),
          ),
      ]),
    );
    await saving;

    expect(form.phase, isA<EditGroupConflict>());
    final review = await editing.refreshedConflictReview(form.editingGroup);
    expect(
      {
        for (final fact in review.comparisonFacts)
          if (fact case skir.EditExpectation_valueWrapper(:final value))
            value.at,
      },
      {_name, _position},
    );
    expect(
      review.saved.valueAt(_name),
      skir.DataValue.wrapStringValue("Saved"),
    );
    expect(
      review.saved.valueAt(_position),
      skir.DataValue.wrapStringValue("Saved"),
    );
  });

  test(
    "rapid renames save once and are refused only when the saved name changed",
    () async {
      final world = testWorld([
        ...adaServing(
          authoredDoc([
            authoredRecord(_resource, texts({"name": "", "position": "0"})),
          ]).document,
        ),
        heldSaves,
      ]);
      final realm = world.requireRealm;
      final editing = await world.openRealmEditing();
      final form = editing.form(_resource);
      for (final name in ["Q", "Qu", "Quest"]) {
        form.setText("Rename", _name, name);
      }
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      final request = realm.saves.single.edit;
      expect(realm.document.facts.conflicts(request.expectations), isEmpty);
      expect(
        authoredDoc([
          authoredRecord(_resource, texts({"name": "Q", "position": "0"})),
        ]).document.facts.conflicts(request.expectations),
        isNotEmpty,
      );
      expect(
        editing.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Quest"),
      );
      realm.saves.last.confirm(
        saved: authoredDoc([
          authoredRecord(_resource, texts({"name": "Quest", "position": "0"})),
        ]).document,
      );
      await saving;
      expect(editing.state.groups, isEmpty);
    },
  );

  test(
    "graph work survives closing its surface and closes after discard",
    () async {
      final world = await signedInWorld(_original);
      final surface = world.container.listen(
        realmEditingProvider(world.requireRealm.scope),
        (_, _) {},
      );
      surface.read().setText(
        "Rename",
        _name,
        "Retained",
        policy: EditorCommitPolicy.applyResource,
      );

      surface.close();
      await world.container.pump();

      final work = world.container.read(localWorkProvider);
      expect(work.entries.values.single.label, "Rename");
      expect(work.blocksNavigation, isTrue);
      expect(
        world.container
            .read(localWorkProvider.notifier)
            .discard(work.entries.keys.single),
        isTrue,
      );
      await world.container.pump();
      expect(world.container.read(localWorkProvider).entries, isEmpty);
      expect(
        (await world.openRealmEditing()).document.valueAt(_name),
        skir.DataValue.wrapStringValue("Original"),
      );
    },
  );
  test("preparation is visible before any graph operation exists", () async {
    final world = await signedInWorld(_original);
    final surface = world.container.listen(
      realmEditingProvider(world.requireRealm.scope),
      (_, _) {},
    );
    final workspace = surface.read();
    final gate = Completer<void>();
    final preparing = workspace.prepare(
      label: "Prepare rename",
      policy: EditorCommitPolicy.applyResource,
      apply: (edit) async {
        await gate.future;
        edit.set(_name, skir.DataValue.wrapStringValue("Prepared"));
      },
    );
    LocalWorkState work() => world.container.read(localWorkProvider);
    expect(workspace.state.groups, isEmpty);
    await world.container.eventually(
      localWorkProvider,
      (work) => work.entries.values.any(
        (entry) => entry.phase == "Preparing changes",
      ),
      description: "the preparation listed as local work",
    );
    expect(work().blocksNavigation, isTrue);

    surface.close();
    await world.container.pump();
    gate.complete();

    expect(await preparing, isA<EditStaged>());
    await world.container.eventually(
      localWorkProvider,
      (work) => work.entries.values.map((entry) => entry.label).toList().equals(
        ["Prepare rename"],
      ),
      description: "the prepared rename as the only local work",
    );
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Prepared"),
    );
  });
  test("two views share changes and detach retains their work", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final workspace = await world.openRealmEditing();
    final first = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    final second = workspace.form(_resource);
    first.setText("Rename", _name, "Local");
    expect(
      second.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(second.dirty, isTrue);
    first.detach();
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Local"),
    );
    second.discard();
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Original"),
    );
    expect(realm.saves, isEmpty);
  });

  test(
    "independent placement save excludes pending name and survives discard",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_resource)..setText("Rename", _name, "Local");
      final moved = workspace.setText(
        "Move",
        _position,
        "50",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      final saving = workspace.save(moved.group);
      await Future<void>.delayed(Duration.zero);
      expect(realm.saves, hasLength(1));
      realm.saves.single.confirm();
      await world.container.pump();
      expect(
        realm.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(
        realm.document.valueAt(_position),
        skir.DataValue.wrapStringValue("50"),
      );
      await saving;
      expect(
        workspace.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(
        workspace.document.valueAt(_position),
        skir.DataValue.wrapStringValue("50"),
      );
      form.discard();
      expect(
        workspace.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(
        workspace.document.valueAt(_position),
        skir.DataValue.wrapStringValue("50"),
      );
    },
  );

  test(
    "overlapping change waits without applying manual predecessor",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_resource)..setText("Rename", _name, "Local");
      final second = workspace.setText(
        "Rename again",
        _name,
        "Next",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      expect(
        workspace.state.groups[second.group]!.phase,
        isA<EditGroupAwaitingDependency>(),
      );
      await workspace.save(second.group);
      expect(realm.saves, isEmpty);
      form.discard();
      expect(
        workspace.state.groups[second.group]!.phase,
        isA<EditGroupConflict>(),
      );
      expect(
        workspace.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Next"),
      );
    },
  );

  test("failed primitive rejects the whole operation", () async {
    final world = testWorld([..._original, heldSaves]);
    final workspace = await world.openRealmEditing();
    final result = workspace.edit(
      label: "Invalid batch",
      apply: (edit) {
        edit
          ..set(_name, skir.DataValue.wrapStringValue("Local"))
          ..set(
            skir.ValueLocation(
              resource: skir.ResourceId(value: "absent"),
              path: _name.path,
            ),
            skir.DataValue.wrapStringValue("Bad"),
          );
      },
    );
    expect(result, isA<EditStageRejected>());
    expect(workspace.state.groups, isEmpty);
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Original"),
    );
  });

  test("editing while saving retains only the later operation", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final workspace = await world.openRealmEditing();
    final form = workspace.form(_resource)..setText("Rename", _name, "First");
    final saving = form.save();
    await Future<void>.delayed(Duration.zero);
    form.setText("Continue", _name, "Second");
    realm.saves.last.confirm(
      saved: authoredDoc([
        authoredRecord(_resource, texts({"name": "First", "position": "0"})),
      ]).document,
    );
    await saving;
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Second"),
    );
    expect(form.blocked, isFalse);
    expect(form.dirty, isTrue);
    expect(form.discard(), isTrue);
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("First"),
    );
  });

  final created = skir.ResourceId(value: "created");
  for (final (saved, resource, change, read, expected) in [
    (
      "a rename",
      _resource,
      (AuthoringEdit edit) =>
          edit.set(_name, skir.DataValue.wrapStringValue("Local")),
      (AuthoringDocument document) => document.valueAt(_name),
      equals(skir.DataValue.wrapStringValue("Local")),
    ),
    (
      "a created resource",
      created,
      (AuthoringEdit edit) => edit.create(
        created,
        skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            skir.FieldValue(
              name: "name",
              value: skir.DataValue.wrapStringValue("Created"),
            ),
          ],
        ),
      ),
      (AuthoringDocument document) =>
          document.valueAt(authoredFieldLocation(created, ["name"])),
      equals(skir.DataValue.wrapStringValue("Created")),
    ),
    (
      "a deleted resource",
      _resource,
      (AuthoringEdit edit) => edit.delete(_resource),
      (AuthoringDocument document) => document.entry(_resource),
      isNull,
    ),
  ]) {
    test("an autosave of $saved whose outcome is unknown saves once the "
        "Realm answers without it", () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final form = await world.autosaveReceived(resource, change);
      realm.saves.single.loseReply(TimeoutException("No answer in time"));

      await eventually(() => expect(realm.saves, hasLength(2)));
      realm.saves.last.confirm();
      await eventually(() => expect(form.dirty, isFalse));

      expect(read(realm.document), expected);
      expect(world.saveActivity, isNot(MutationActivityPhase.needsAttention));
    });

    test("an autosave of $saved whose outcome is unknown is not sent again "
        "once the Realm shows it was saved", () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final form = await world.autosaveReceived(resource, change);
      realm.saves.single.keepAndLoseReply(
        TimeoutException("No answer in time"),
      );

      await eventually(() => expect(form.dirty, isFalse));

      expect(realm.saves, hasLength(1));
      expect(read(form.document), expected);
      expect(world.saveActivity, isNot(MutationActivityPhase.needsAttention));
    });
  }

  test("an autosave whose outcome is unknown asks for review when the Realm "
      "holds other values", () async {
    final world = testWorld([..._original, heldSaves]);
    final realm = world.requireRealm;
    final form = await world.autosaveReceived(
      _resource,
      (edit) => edit.set(_name, skir.DataValue.wrapStringValue("Local")),
    );
    realm.saves.single.loseReply(TimeoutException("No answer in time"));
    realm.remoteChange(
      (edit) => edit.set(_name, skir.DataValue.wrapStringValue("Remote")),
    );

    await eventually(
      () => expect(form.phase, isA<EditGroupConflict<AuthoringDocument>>()),
    );

    expect(realm.saves, hasLength(1));
    final review = await form.workspace.refreshedConflictReview(
      form.editingGroup,
    );
    expect(
      review.saved.valueAt(_name),
      skir.DataValue.wrapStringValue("Remote"),
    );
    expect(
      review.proposal.valueAt(_name),
      skir.DataValue.wrapStringValue("Local"),
    );
  });
  for (final uncertain in [false, true]) {
    test(
      "discarding a later unsent edit preserves the ${uncertain ? 'uncertain' : 'committed'} prefix",
      () async {
        final world = testWorld([..._original, heldSaves]);
        final realm = world.requireRealm
          ..refreshFailure = StateError("Refresh unavailable");
        final workspace = await world.openRealmEditing();
        final binding = workspace.form(_resource)
          ..setText("First", _name, "First");
        final saving = binding.save();
        await Future<void>.delayed(Duration.zero);
        binding.setText("Later", _name, "Later");
        if (uncertain) {
          realm.saves.last.loseReply(StateError("Reply lost"));
        } else {
          realm.saves.last.confirm(observed: false);
        }
        await saving;
        final phase = binding.phase;
        expect(binding.control.state.canDiscard, isTrue);
        expect(binding.discard(), isTrue);
        expect(binding.phase, phase);
        expect(binding.hasSubmittedWork, isTrue);
        expect(
          binding.document.valueAt(_name),
          skir.DataValue.wrapStringValue("First"),
        );
        expect(binding.control.state.canDiscard, isFalse);
        expect(binding.discard(), isFalse);
        await binding.save();
        expect(realm.saves, hasLength(1));
      },
    );
  }

  test(
    "reading a value for display does not make a rename depend on it",
    () async {
      final world = testWorld(_original);
      final realm = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_resource);
      final displayed = workspace.document..read(_position);
      form.setText("Rename", _name, "Next");

      realm.serve(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Original", "position": "Remote"}),
          ),
        ]).document,
      );
      await world.container.pump();

      expect(form.blocked, isFalse);
      expect(
        displayed.valueAt(_name),
        skir.DataValue.wrapStringValue("Original"),
      );
      await form.save();
      expect(
        realm.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Next"),
      );
      expect(
        realm.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Remote"),
      );
    },
  );

  test(
    "catalog changes retain pending values and block every preparation",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_resource)..setText("Rename", _name, "Local");
      final changed =
          authoredDoc([
            authoredRecord(
              _resource,
              texts({"name": "Original", "position": "0"}),
            ),
          ]).document.copyWith(
            catalog: libraryCatalog(
              generation: skir.CatalogGeneration(value: "next"),
            ),
          );
      workspace.acceptConfirmed(changed);
      expect(form.phase, isA<EditGroupContractChanged>());
      expect(
        form.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(
        await workspace.prepare(
          label: "New",
          apply: (edit) async =>
              edit.set(_position, skir.DataValue.wrapStringValue("50")),
        ),
        isA<EditStageRejected>(),
      );
      form.discard();
      expect(workspace.document.generation, changed.generation);
    },
  );

  test(
    "unrelated remote changes merge while guarded changes retain a conflict",
    () async {
      final workspace = await testWorld(_original).openRealmEditing();
      final form = workspace.form(_resource)..setText("Rename", _name, "Local");
      workspace.acceptConfirmed(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Original", "position": "Remote"}),
          ),
        ]).document,
      );
      expect(form.blocked, isFalse);
      expect(
        workspace.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Remote"),
      );
      workspace.acceptConfirmed(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Remote", "position": "Remote"}),
          ),
        ]).document,
      );
      expect(form.phase, isA<EditGroupConflict>());
      expect(
        workspace.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      form.discard();
      expect(
        workspace.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Remote"),
      );
    },
  );

  test(
    "delayed preparation rejects changed facts but accepts unrelated changes",
    () async {
      final workspace = await testWorld(_original).openRealmEditing();
      for (final changedName in [false, true]) {
        final gate = Completer<void>();
        final pending = workspace.prepare(
          label: "Prepared rename",
          policy: EditorCommitPolicy.applyResource,
          apply: (edit) async {
            edit.expect(_name);
            await gate.future;
            edit.set(_name, skir.DataValue.wrapStringValue("Prepared"));
          },
        );
        workspace.acceptConfirmed(
          authoredDoc([
            authoredRecord(
              _resource,
              texts({
                "name": changedName ? "Remote" : "Original",
                "position": "Remote",
              }),
            ),
          ]).document,
        );
        gate.complete();
        final result = await pending;
        expect(
          result,
          changedName ? isA<EditStageRejected>() : isA<EditStaged>(),
        );
        if (result is EditStaged) workspace.discard(result.group);
      }
    },
  );

  test("closing a binding cancels delayed publication without discarding prior work", () async {
    final workspace = await testWorld(_original).openRealmEditing();
    final binding = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    )..setText("Prior", _position, "Prior");
    final gate = Completer<void>();
    final pending = binding.prepare(
      label: "Delayed",
      apply: (edit) async {
        edit.expect(_name);
        await gate.future;
        edit.set(_name, skir.DataValue.wrapStringValue("Delayed"));
      },
    );
    binding.detach();
    gate.complete();
    expect(await pending, isA<EditStageRejected>());
    expect(
      workspace.document.valueAt(_name),
      skir.DataValue.wrapStringValue("Original"),
    );
    expect(
      workspace.document.valueAt(_position),
      skir.DataValue.wrapStringValue("Prior"),
    );
  });

  for (final observed in [false, true]) {
    test(
      observed
          ? "a commit whose refresh failed recovers when its saved values are "
                "observed again, even while that observation rebuilds"
          : "a known committed prefix refreshes without replaying and retains "
                "its tail",
      () async {
        final world = testWorld([..._original, heldSaves]);
        final realm = world.requireRealm
          ..refreshFailure = StateError("Refresh lost");
        final workspace = await world.openRealmEditing();
        final form = workspace.form(_resource)
          ..setText("First", _name, "First");
        final saving = form.save();
        await Future<void>.delayed(Duration.zero);
        form.setText("Tail", _name, "Tail");
        realm.saves.last.confirm(observed: false);
        await saving;
        expect(form.phase, isA<EditGroupCommittedAwaitingRefresh>());
        expect(form.control.state.canDiscard, isTrue);
        realm.refreshFailure = null;
        if (observed) {
          realm
            ..announceRefreshes()
            ..remoteChange((_) {});
        } else {
          await workspace.refreshConfirmed();
        }
        await eventually(
          () => expect(
            form.phase,
            isNot(isA<EditGroupCommittedAwaitingRefresh>()),
          ),
        );
        expect(realm.saves, hasLength(1));
        expect(
          workspace.document.valueAt(_name),
          skir.DataValue.wrapStringValue("Tail"),
        );
        expect(form.blocked, isFalse);
      },
    );
  }

  test(
    "the lane orders independent groups and excludes unrelated form work",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final first = workspace.setText(
        "Name",
        _name,
        "First",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      final second = workspace.setText(
        "Position",
        _position,
        "Second",
        policy: EditorCommitPolicy.applyResource,
      ) as EditStaged;
      final saving = workspace.save(first.group);
      await Future<void>.delayed(Duration.zero);
      unawaited(workspace.save(second.group));
      expect(realm.saves, hasLength(1));
      realm.saves.last.confirm();
      await Future<void>.delayed(Duration.zero);
      expect(realm.saves, hasLength(2));
      final positionOnly = AuthoringEdit.fromDocument(
        authoredDoc([
          authoredRecord(
            _resource,
            texts({"name": "Original", "position": "0"}),
          ),
        ]).document,
      )..applyPrepared(realm.saves.last.edit);
      expect(
        positionOnly.toDocument().valueAt(_name),
        skir.DataValue.wrapStringValue("Original"),
      );
      expect(
        positionOnly.toDocument().valueAt(_position),
        skir.DataValue.wrapStringValue("Second"),
      );
      realm.saves.last.confirm();
      await saving;
      expect(workspace.state.groups, isEmpty);
      expect(
        realm.document.valueAt(_name),
        skir.DataValue.wrapStringValue("First"),
      );
      expect(
        realm.document.valueAt(_position),
        skir.DataValue.wrapStringValue("Second"),
      );
    },
  );

  test(
    "rejected saves retain their proposal without an automatic retry",
    () async {
      final world = testWorld([..._original, heldSaves]);
      final realm = world.requireRealm;
      final workspace = await world.openRealmEditing();
      final form = workspace.form(_resource)..setText("Rename", _name, "Local");
      final saving = form.save();
      await Future<void>.delayed(Duration.zero);
      realm.saves.last.reject(
        skir.CommitPreparedEditResponse.wrapConflictError(const []),
      );
      await saving;
      await form.save();
      expect(form.phase, isA<EditGroupConflict>());
      expect(
        form.document.valueAt(_name),
        skir.DataValue.wrapStringValue("Local"),
      );
      expect(realm.saves, hasLength(1));
      expect(form.discard(), isTrue);
    },
  );

  test("missing resources retain their proposal for comparison", () async {
    final workspace = await testWorld(_original).openRealmEditing();
    final form = workspace.form(_resource)
      ..setText("Rename", _name, "Retained");
    workspace.acceptConfirmed(
      authoredDoc([
        authoredRecord(_resource, texts({"name": "Original", "position": "0"})),
      ]).document.copyWith(entries: const {}),
    );
    final phase = form.phase! as EditGroupResourceMissing;
    expect(
      (phase.proposal as AuthoringDocument).valueAt(_name),
      skir.DataValue.wrapStringValue("Retained"),
    );
    expect(form.discard(), isTrue);
    expect(workspace.state.groups, isEmpty);
  });

  test(
    "record field order is irrelevant but collection item order is guarded",
    () async {
      final document = authoredDoc([
        authoredRecord(_resource, texts({"name": "Original", "position": "0"})),
      ]).document;
      final workspace = await testWorld(adaServing(document))
          .openRealmEditing();
      final form = workspace.form(_resource);
      final root = skir.ValueLocation(
        resource: _resource,
        path: skir.ValuePath(segments: const []),
      );
      form.edit(
        label: "Guard record",
        apply: (edit) {
          edit
            ..expect(root)
            ..set(_position, skir.DataValue.wrapStringValue("Next"));
        },
      );
      final entry = document.entry(_resource)!;
      workspace.acceptConfirmed(
        document.copyWith(
          entries: {
            _resource: skir.AuthoringResource(
              id: _resource,
              content: skir.AuthoringRecord(
                configuration: entry.content.configuration,
                fields: entry.content.fields.toList().reversed,
              ),
            ),
          },
        ),
      );
      expect(form.blocked, isFalse);
      form.discard();
      final itemsAt = authoredFieldLocation(_resource, ["items"]);
      skir.DataValue items(List<String> ids) => skir.DataValue.createListValue(
        items: ids.map(
          (id) => skir.ListItem(
            id: skir.ItemId(value: id),
            value: skir.DataValue.wrapStringValue(id),
          ),
        ),
      );
      final prepared = AuthoringEdit.fromDocument(document)
        ..set(itemsAt, items(["first", "second"]));
      workspace.acceptConfirmed(prepared.toDocument());
      form.edit(
        label: "Guard collection",
        apply: (edit) {
          edit
            ..expect(itemsAt)
            ..set(_position, skir.DataValue.wrapStringValue("Next"));
        },
      );
      final remote = AuthoringEdit.fromDocument(prepared.toDocument())
        ..set(itemsAt, items(["second", "first"]));
      workspace.acceptConfirmed(remote.toDocument());
      expect(form.phase, isA<EditGroupConflict>());
    },
  );

  test("unsent work outlives its view and returns when the Realm is "
      "opened again", () async {
    final world = await signedInWorld(_original);
    final scope = world.requireRealm.scope;
    final view = world.container.listen(realmEditingProvider(scope), (_, _) {});
    view.read().attach(_resource, policy: EditorCommitPolicy.applyResource)
      ..setText("Rename", _name, "Local")
      ..detach();

    view.close();
    await world.container.pump();

    expect(
      world.container
          .read(workingAuthoringDocumentProvider(scope))
          .requireValue
          .valueAt(_name),
      skir.DataValue.wrapStringValue("Local"),
    );
    expect(world.realm!.saves, isEmpty);
  });
}

final _resource = skir.ResourceId(value: "resource");
final _name = skir.ValueLocation(
  resource: _resource,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "name")]),
);
final _position = skir.ValueLocation(
  resource: _resource,
  path: skir.ValuePath(
    segments: [skir.PathSegment.createField(name: "position")],
  ),
);
