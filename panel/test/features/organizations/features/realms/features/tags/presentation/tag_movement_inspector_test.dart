import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  for (final (movement, stage) in [
    (_Movement.keyboard, "before submission"),
    (_Movement.keyboard, "awaiting acknowledgement"),
    (_Movement.keyboard, "awaiting saved values"),
    (_Movement.drag, "before submission"),
  ]) {
    testWidgets(
      "${movement.name} movement keeps inspector controls hidden $stage",
      (tester) async {
        final fixture = await _mount(tester);
        expect(_inspectorActions(), isEmpty);

        await _move(tester, movement);
        expect(
          Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
          3,
        );
        expect(fixture.boundary.requests, isEmpty);
        expect(
          fixture.editing.state.groups.values.single.phase,
          isA<EditGroupDirty>(),
        );
        final beforeSubmission = _inspectorActions();

        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(fixture.boundary.requests, hasLength(1));
        expect(
          fixture.editing.state.groups.values.single.phase,
          isA<EditGroupSaving>(),
        );
        final awaitingAcknowledgement = _inspectorActions();

        fixture.boundary.accept();
        await tester.pump();
        await tester.pump();
        expect(fixture.boundary.observations, hasLength(1));
        final phase =
            fixture.editing.state.groups.values.single.phase
                as EditGroupCommittedAwaitingRefresh;
        expect(phase.cause, isNull);
        final awaitingSavedValues = _inspectorActions();

        fixture.boundary.observations.single.complete(_document(x: 3));
        await tester.pumpAndSettle();
        expect(fixture.editing.hasPendingWork, isFalse);
        expect(fixture.boundary.requests, hasLength(1));
        expect(_inspectorActions(), isEmpty);
        expect(tester.takeException(), isNull);

        final actions = switch (stage) {
          "before submission" => beforeSubmission,
          "awaiting acknowledgement" => awaitingAcknowledgement,
          "awaiting saved values" => awaitingSavedValues,
          _ => throw StateError("Unknown save stage"),
        };
        expect(
          actions,
          isEmpty,
          reason:
              "A successful automatic move must not expose a temporary "
              "save or review panel in the inspector $stage",
        );
      },
    );
  }

  testWidgets("repeated movement keeps dependent automatic saves hidden", (
    tester,
  ) async {
    final fixture = await _mount(tester);
    await _move(tester, _Movement.keyboard);
    await _move(tester, _Movement.keyboard);
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
      4,
    );
    expect(fixture.editing.state.groups, hasLength(2));
    expect(
      fixture.editing.state.groups.values.any(
        (group) => group.phase is EditGroupAwaitingDependency,
      ),
      isTrue,
    );
    final actions = <List<String>>[_inspectorActions()];

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(fixture.boundary.requests, hasLength(1));
    actions.add(_inspectorActions());
    fixture.boundary.accept();
    await tester.pump();
    actions.add(_inspectorActions());
    fixture.boundary.observations.single.complete(_document(x: 3));
    await tester.pump();
    await tester.pump();
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
      4,
    );
    actions.add(_inspectorActions());

    final remaining = fixture.editing.state.groups.values.single;
    expect(remaining.policy, EditorCommitPolicy.autosaveChanges);
    expect(remaining.phase, isA<EditGroupDirty>());
    expect(fixture.editing.canSave(remaining.id), isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(fixture.boundary.requests, hasLength(2));
    actions.add(_inspectorActions());
    fixture.boundary.accept(1);
    await tester.pump();
    expect(fixture.boundary.observations, hasLength(2));
    actions.add(_inspectorActions());
    fixture.boundary.observations.last.complete(_document(x: 4));
    await tester.pumpAndSettle();
    expect(fixture.editing.hasPendingWork, isFalse);
    expect(_inspectorActions(), isEmpty);
    expect(tester.takeException(), isNull);
    expect(
      actions,
      everyElement(isEmpty),
      reason: "Waiting on another automatic move is normal save progress",
    );
  });

  testWidgets("rejected movement retains inspector recovery controls", (
    tester,
  ) async {
    final fixture = await _mount(tester);
    await _move(tester, _Movement.keyboard);
    await tester.pump(const Duration(milliseconds: 250));
    expect(fixture.boundary.requests, hasLength(1));
    fixture.boundary.requests.single.response.complete(
      skir.CommitPreparedEditResponse.wrapResult(
        skir.CommitResult.wrapRejected(const []),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      fixture.editing.state.groups.values.single.phase,
      isA<EditGroupRejected>(),
    );
    expect(
      _inspectorActions(),
      containsAll(["Move tags", "Discard", "Retry", "Apply", "View changes"]),
    );
    expect(fixture.boundary.observations, isEmpty);
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
      3,
    );

    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(fixture.editing.hasPendingWork, isFalse);
    expect(_inspectorActions(), isEmpty);
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
      2,
    );
    expect(fixture.boundary.requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets("failed movement refresh retains inspector recovery controls", (
    tester,
  ) async {
    final fixture = await _mount(tester);
    await _move(tester, _Movement.keyboard);
    await tester.pump(const Duration(milliseconds: 250));
    fixture.boundary.accept();
    await tester.pump();
    final failure = StateError("Saved placement is unavailable");
    fixture.boundary.observations.single.completeError(failure);
    await tester.pump();
    await tester.pump();

    final group = fixture.editing.state.groups.values.single;
    expect(
      (group.phase as EditGroupCommittedAwaitingRefresh).cause,
      same(failure),
    );
    expect(
      _inspectorActions(),
      containsAll(["Move tags", "Retry", "Refresh", "View changes"]),
    );
    expect(_inspectorActions(), isNot(contains("Discard")));
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).placement.x,
      3,
    );

    await tester.tap(find.text("Retry"));
    await tester.pump();
    expect(fixture.boundary.observations, hasLength(2));
    fixture.boundary.observations.last.complete(_document(x: 3));
    await tester.pumpAndSettle();
    expect(fixture.boundary.requests, hasLength(1));
    expect(fixture.editing.hasPendingWork, isFalse);
    expect(_inspectorActions(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets("manual related drafts retain inspector Apply and Discard", (
    tester,
  ) async {
    final fixture = await _mount(tester);
    fixture.editing
        .edit(
          label: "Rename tag",
          policy: EditorCommitPolicy.applyResource,
          apply: (edit) => edit.set(
            authoredFieldLocation(_tag, ["name"]),
            skir.DataValue.wrapStringValue("Draft"),
          ),
        )
        .requireAccepted();
    await tester.pump();
    expect(
      _inspectorActions(),
      containsAll(["Apply", "Discard", "View changes"]),
    );
    expect(fixture.boundary.requests, isEmpty);

    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(fixture.editing.hasPendingWork, isFalse);
    expect(_inspectorActions(), isEmpty);
    expect(
      Tag.fromAuthoring(fixture.editing.document.entry(_tag)!).name,
      "Tag",
    );
    expect(fixture.boundary.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

enum _Movement { keyboard, drag }

final _scope = AuthoringScope(
  organizationId: skir.recordId("organization:fixture"),
  realmId: skir.recordId("realm:fixture"),
);
final _tag = skir.ResourceId(value: "tag:movement");

AuthoringDocument _document({int x = 2}) => fixtureAuthoringDocument(
  tags: [
    Tag(
      tagId: _tag,
      name: "Tag",
      color: Colors.blue,
      parentIds: const [],
      placement: GraphPlacement(x: x, y: 3, width: 2, height: 1),
    ),
  ],
);

Future<({RealmEditing editing, _SaveBoundary boundary})> _mount(
  WidgetTester tester,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final boundary = _SaveBoundary();
  final transport = ScriptedAuthoringTransport(AsyncData(_document()));
  addTearDown(transport.dispose);
  await tester.pumpTestApp(
    overrides: [
      ...authoringFixtureOverrides(scope: _scope, transport: transport),
      realmEditPersistenceProvider(_scope).overrideWithValue(
        fixtureRealmPersistence(
          commit: boundary.commit,
          confirmed: boundary.observe,
        ),
      ),
    ],
    child: Scaffold(
      body: Row(
        children: [
          const Expanded(child: TagGraph()),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, child) => AuthoredResourceInspection(
                  resource: _tag,
                  workspace: ref.watch(realmEditingProvider(_scope)),
                  commands: fixtureAuthoringCommands(transport),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TagGraph)),
  );
  container
      .read(selectionProvider.notifier)
      .select(AuthoringResourceIdentifier.inScope(_scope, _tag));
  await tester.pump();
  return (
    editing: container.read(realmEditingProvider(_scope)),
    boundary: boundary,
  );
}

Future<void> _move(WidgetTester tester, _Movement movement) async {
  switch (movement) {
    case _Movement.keyboard:
      final selector = tester.widget<Selector>(find.byType(Selector));
      selector.focusNode.requestFocus();
      await tester.pump();
      Actions.invoke(
        selector.focusNode.context!,
        const GraphMoveIntent(direction: TraversalDirection.right),
      );
    case _Movement.drag:
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(TagNode)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(tagGraphCellSize, 0));
      await tester.pump();
      await gesture.up();
  }
  await tester.pump();
}

List<String> _inspectorActions() => find
    .descendant(
      of: find.byType(AuthoredResourceInspection),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            const {
              "Move tags",
              "Apply",
              "Discard",
              "Retry",
              "Refresh",
              "View changes",
            }.contains(widget.data),
      ),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data!)
    .toList();

/// Holds only external replies. Graph, editing, and inspection run real code.
final class _SaveBoundary {
  final requests = <ScriptedAuthoringRequest>[];
  final observations = <Completer<AuthoringDocument>>[];

  Future<skir.CommitPreparedEditResponse> commit(skir.PreparedEdit edit) {
    final request = ScriptedAuthoringRequest(edit);
    requests.add(request);
    return request.response.future;
  }

  Future<AuthoringDocument> observe() {
    final observation = Completer<AuthoringDocument>();
    observations.add(observation);
    return observation.future;
  }

  void accept([int index = 0]) => requests[index].response.complete(
    skir.CommitPreparedEditResponse.wrapResult(skir.CommitResult.committed),
  );
}
