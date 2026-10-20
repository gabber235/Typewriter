import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  for (final stage in [
    "before submission",
    "awaiting acknowledgement",
    "awaiting saved values",
  ]) {
    testWidgets("typing a tag name keeps inspector controls hidden $stage", (
      tester,
    ) async {
      final fixture = await _mount(tester);
      final input = find.byType(TextFormField);
      final initialHeight = tester
          .getSize(find.byType(AuthoredResourceInspection))
          .height;
      await tester.tap(input);
      await tester.enterText(input, "Renamed");
      await tester.pump();
      final element = tester.element(input);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(
        Tag.fromAuthoring(
          fixture.editing.document.entry(_tag)!,
          fixture.editing.document.catalog.appearanceOf(
            fixture.editing.document.entry(_tag)!.content,
          ),
        ).name,
        "Renamed",
      );
      expect(fixture.editing.state.groups, hasLength(1));
      expect(
        find.byWidgetPredicate((widget) => widget is EditingGroupPanel),
        findsNothing,
        reason: "Typing must exercise the inspector's own group",
      );
      expect(fixture.boundary.requests, isEmpty);
      final beforeSubmission = _inspectorActions();
      expect(
        tester.getSize(find.byType(AuthoredResourceInspection)).height,
        initialHeight,
      );

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(fixture.boundary.requests, hasLength(1));
      expect(
        fixture.editing.state.groups.values.single.phase,
        isA<EditGroupSaving>(),
      );
      final awaitingAcknowledgement = _inspectorActions();
      expect(
        tester.getSize(find.byType(AuthoredResourceInspection)).height,
        initialHeight,
      );

      fixture.boundary.accept();
      await tester.pump();
      await tester.pump();
      expect(fixture.boundary.observations, hasLength(1));
      final phase =
          fixture.editing.state.groups.values.single.phase
              as EditGroupCommittedAwaitingRefresh;
      expect(phase.cause, isNull);
      final awaitingSavedValues = _inspectorActions();
      expect(
        tester.getSize(find.byType(AuthoredResourceInspection)).height,
        initialHeight,
      );

      fixture.boundary.observations.single.complete(_document(name: "Renamed"));
      await tester.pumpAndSettle();
      expect(fixture.editing.hasPendingWork, isFalse);
      expect(_inspectorActions(), isEmpty);
      expect(tester.element(input), same(element));
      final retained = tester.widget<EditableText>(find.byType(EditableText));
      expect(retained.controller, same(editable.controller));
      expect(retained.focusNode, same(editable.focusNode));
      expect(retained.focusNode.hasFocus, isTrue);
      expect(retained.controller.text, "Renamed");
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
        reason: "Automatic name edits must not flash save controls $stage",
      );
    });
  }

  testWidgets(
    "typing during a pending name save keeps controls hidden and retains later edits",
    (tester) async {
      final fixture = await _mount(tester);
      final input = find.byType(TextFormField);
      await tester.enterText(input, "First name");
      await tester.pump();
      final actions = <List<String>>[_inspectorActions()];
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(fixture.boundary.requests, hasLength(1));
      actions.add(_inspectorActions());

      await tester.enterText(input, "Later name");
      await tester.pump();
      expect(fixture.boundary.requests, hasLength(1));
      expect(
        Tag.fromAuthoring(
          fixture.editing.document.entry(_tag)!,
          fixture.editing.document.catalog.appearanceOf(
            fixture.editing.document.entry(_tag)!.content,
          ),
        ).name,
        "Later name",
      );
      actions.add(_inspectorActions());
      fixture.boundary.accept();
      await tester.pump();
      actions.add(_inspectorActions());
      fixture.boundary.observations.single.complete(
        _document(name: "First name"),
      );
      await tester.pump();
      expect(
        Tag.fromAuthoring(
          fixture.editing.document.entry(_tag)!,
          fixture.editing.document.catalog.appearanceOf(
            fixture.editing.document.entry(_tag)!.content,
          ),
        ).name,
        "Later name",
      );
      actions.add(_inspectorActions());

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(fixture.boundary.requests, hasLength(2));
      actions.add(_inspectorActions());
      fixture.boundary.accept(1);
      await tester.pump();
      fixture.boundary.observations.last.complete(
        _document(name: "Later name"),
      );
      await tester.pumpAndSettle();
      expect(fixture.editing.hasPendingWork, isFalse);
      expect(_inspectorActions(), isEmpty);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        "Later name",
      );
      expect(tester.takeException(), isNull);
      expect(actions, everyElement(isEmpty));
    },
  );

  testWidgets(
    "manual name edits retain controls without automatically saving",
    (tester) async {
      final fixture = await _mount(
        tester,
        policy: EditorCommitPolicy.applyResource,
      );
      await tester.enterText(find.byType(TextFormField), "Manual draft");
      await tester.pump(const Duration(milliseconds: 500));
      expect(fixture.boundary.requests, isEmpty);
      expect(_inspectorActions(), containsAll(["Apply", "Discard"]));
      await tester.tap(find.text("Discard"));
      await tester.pumpAndSettle();
      expect(
        Tag.fromAuthoring(
          fixture.editing.document.entry(_tag)!,
          fixture.editing.document.catalog.appearanceOf(
            fixture.editing.document.entry(_tag)!.content,
          ),
        ).name,
        "Tag",
      );
      expect(fixture.editing.hasPendingWork, isFalse);
      expect(_inspectorActions(), isEmpty);
    },
  );

  testWidgets("rejected name edits retain inspector recovery controls", (
    tester,
  ) async {
    final fixture = await _mount(tester);
    await tester.enterText(find.byType(TextFormField), "Retained draft");
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
    expect(_inspectorActions(), containsAll(["Discard", "Retry", "Apply"]));
    expect(
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).name,
      "Retained draft",
    );
    expect(fixture.boundary.requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

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
        final initialHeight = tester
            .getSize(find.byType(AuthoredResourceInspection))
            .height;

        await _move(tester, movement);
        expect(
          Tag.fromAuthoring(
            fixture.editing.document.entry(_tag)!,
            fixture.editing.document.catalog.appearanceOf(
              fixture.editing.document.entry(_tag)!.content,
            ),
          ).placement.x,
          3,
        );
        expect(fixture.boundary.requests, isEmpty);
        expect(
          fixture.editing.state.groups.values.single.phase,
          isA<EditGroupDirty>(),
        );
        final beforeSubmission = _inspectorActions();
        expect(
          tester.getSize(find.byType(AuthoredResourceInspection)).height,
          initialHeight,
        );

        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump();
        expect(fixture.boundary.requests, hasLength(1));
        expect(
          fixture.editing.state.groups.values.single.phase,
          isA<EditGroupSaving>(),
        );
        final awaitingAcknowledgement = _inspectorActions();
        expect(
          tester.getSize(find.byType(AuthoredResourceInspection)).height,
          initialHeight,
        );

        fixture.boundary.accept();
        await tester.pump();
        await tester.pump();
        expect(fixture.boundary.observations, hasLength(1));
        final phase =
            fixture.editing.state.groups.values.single.phase
                as EditGroupCommittedAwaitingRefresh;
        expect(phase.cause, isNull);
        final awaitingSavedValues = _inspectorActions();
        expect(
          tester.getSize(find.byType(AuthoredResourceInspection)).height,
          initialHeight,
        );

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
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).placement.x,
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
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).placement.x,
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
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).placement.x,
      3,
    );

    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(fixture.editing.hasPendingWork, isFalse);
    expect(_inspectorActions(), isEmpty);
    expect(
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).placement.x,
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
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).placement.x,
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
      Tag.fromAuthoring(
        fixture.editing.document.entry(_tag)!,
        fixture.editing.document.catalog.appearanceOf(
          fixture.editing.document.entry(_tag)!.content,
        ),
      ).name,
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

AuthoringDocument _document({int x = 2, String name = "Tag"}) =>
    fixtureAuthoringDocument(
      tags: [
        Tag(
          tagId: _tag,
          name: name,
          color: Colors.blue,
          parentIds: const [],
          placement: GraphPlacement(x: x, y: 3, width: 2, height: 1),
        ),
      ],
    );

Future<({RealmEditing editing, _SaveBoundary boundary})> _mount(
  WidgetTester tester, {
  EditorCommitPolicy policy = EditorCommitPolicy.autosaveChanges,
}) async {
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
                  commitPolicy: policy,
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
      await tester.drag(
        find.byType(TagNode),
        const Offset(tagGraphCellSize, 0),
      );
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
