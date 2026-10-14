import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../support/test_utils.dart";

ValueEditing _owner({
  EditorCommitter? commit,
  EditorCommitPolicy policy = EditorCommitPolicy.applyResource,
  ScopedWorkSession? session,
}) => ValueEditing(
  document: EditorDocument(
    rootType: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    confirmedValue: skir.DataValue.wrapStringValue("Saved"),
    revision: 1,
  ),
  validation: (path, value) => EditorMutationResult.applied(value),
  commitPolicy: policy,
  workspace: session,
  commit: commit,
);
void main() {
  for (final stage in ["before submission", "awaiting acknowledgement"]) {
    testWidgets("automatic value controls stay hidden $stage", (tester) async {
      final reply = Completer<TypedMutationResult>();
      final commits = <EditorCommit>[];
      final owner = _owner(
        policy: EditorCommitPolicy.autosaveChanges,
        commit: (commit) {
          commits.add(commit);
          return reply.future;
        },
      );
      final control = owner.bindControl();
      addTearDown(control.dispose);
      addTearDown(owner.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: control)),
      );
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      expect(owner.hasWork, isTrue);
      expect(control.state.hasWork, isTrue);
      final beforeSubmission = _visibleActions();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(commits, hasLength(1));
      expect(control.state.hasSubmittedWork, isTrue);
      final awaitingAcknowledgement = _visibleActions();
      reply.complete(
        TypedMutationResult.success(
          revision: 2,
          value: skir.DataValue.wrapStringValue("Draft"),
        ),
      );
      await tester.pumpAndSettle();
      expect(control.state.hasWork, isFalse);
      expect(_visibleActions(), isEmpty);
      expect(commits, hasLength(1));
      expect(
        stage == "before submission"
            ? beforeSubmission
            : awaitingAcknowledgement,
        isEmpty,
        reason: "Shared controls must keep healthy automatic work hidden",
      );
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
    });
  }

  testWidgets(
    "selection of healthy automatic owners keeps shared controls hidden",
    (tester) async {
      final replies = [
        Completer<TypedMutationResult>(),
        Completer<TypedMutationResult>(),
      ];
      final commits = <EditorCommit>[];
      final owners = [
        for (var index = 0; index < 2; index++)
          _owner(
            policy: EditorCommitPolicy.autosaveChanges,
            commit: (commit) {
              commits.add(commit);
              return replies[index].future;
            },
          ),
      ];
      final members = owners.map((owner) => owner.bindControl()).toList();
      final selection = EditSelectionControl(members);
      addTearDown(() {
        selection.dispose();
        for (final control in members) {
          control.dispose();
        }
        for (final owner in owners) {
          owner.dispose();
        }
      });
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: selection)),
      );
      for (final owner in owners) {
        owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      }
      await tester.pump();
      expect(selection.state.hasWork, isTrue);
      final beforeSubmission = _visibleActions();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(commits, hasLength(2));
      expect(selection.state.hasSubmittedWork, isTrue);
      final awaitingAcknowledgement = _visibleActions();
      for (final reply in replies) {
        reply.complete(
          TypedMutationResult.success(
            revision: 2,
            value: skir.DataValue.wrapStringValue("Draft"),
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(selection.state.hasWork, isFalse);
      expect(_visibleActions(), isEmpty);
      expect([
        beforeSubmission,
        awaitingAcknowledgement,
      ], everyElement(isEmpty));
      await tester.pumpWidget(const SizedBox.shrink());
      for (final owner in owners) {
        owner.dispose();
      }
    },
  );

  testWidgets("automatic group panels keep their label and review hidden", (
    tester,
  ) async {
    final reply = Completer<TypedMutationResult>();
    final owner = _owner(
      policy: EditorCommitPolicy.autosaveChanges,
      commit: (_) => reply.future,
    );
    addTearDown(owner.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: EditingGroupPanel(
          workspace: owner.workspace,
          id: owner.groupId,
          review: () => const Text("Review"),
        ),
      ),
    );
    owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await tester.pump();
    expect(owner.hasWork, isTrue);
    expect(find.text("Edit value"), findsNothing);
    expect(find.text("View changes"), findsNothing);
    expect(_visibleActions(), isEmpty);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(
      owner.workspace.state.groups.values.single.phase,
      isA<EditGroupSaving>(),
    );
    expect(find.text("Edit value"), findsNothing);
    expect(find.text("View changes"), findsNothing);
    expect(_visibleActions(), isEmpty);
    reply.complete(
      TypedMutationResult.success(
        revision: 2,
        value: skir.DataValue.wrapStringValue("Draft"),
      ),
    );
    await tester.pumpAndSettle();
    expect(owner.hasWork, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    owner.dispose();
  });

  testWidgets(
    "combined manual work keeps existing Apply rules while another member saves",
    (tester) async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final reply = Completer<TypedMutationResult>();
      var automaticSends = 0;
      var manualSends = 0;
      final automatic = _owner(
        policy: EditorCommitPolicy.autosaveChanges,
        session: session,
        commit: (_) {
          automaticSends++;
          return reply.future;
        },
      );
      final manual = _owner(
        session: session,
        commit: (capture) async {
          manualSends++;
          return TypedMutationResult.success(
            revision: capture.expectedRevision + 1,
            value: capture.rootValue,
          );
        },
      );
      final members = [automatic.bindControl(), manual.bindControl()];
      final selection = EditSelectionControl(members);
      addTearDown(() {
        selection.dispose();
        for (final control in members) {
          control.dispose();
        }
        automatic.dispose();
        manual.dispose();
      });
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: selection)),
      );
      automatic.update(
        editorRootPath,
        skir.DataValue.wrapStringValue("Automatic"),
      );
      manual.update(editorRootPath, skir.DataValue.wrapStringValue("Manual"));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(automaticSends, 1);
      expect(manualSends, 0);
      expect(selection.state.showControls, isTrue);
      expect(find.text("Apply"), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      reply.complete(
        TypedMutationResult.success(
          revision: 2,
          value: skir.DataValue.wrapStringValue("Automatic"),
        ),
      );
      await tester.pumpAndSettle();
      expect(automatic.hasWork, isFalse);
      expect(manual.hasWork, isTrue);
      expect(selection.state.canApply, isTrue);
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(automaticSends, 1);
      expect(manualSends, 1);
      expect(selection.state.hasWork, isFalse);
      expect(_visibleActions(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      automatic.dispose();
      manual.dispose();
      session.dispose();
    },
  );

  testWidgets("rejected automatic value edits expose recovery controls", (
    tester,
  ) async {
    final owner = _owner(
      policy: EditorCommitPolicy.autosaveChanges,
      commit: (_) async => invalidMutation("Name is unavailable"),
    );
    final control = owner.bindControl();
    addTearDown(control.dispose);
    addTearDown(owner.dispose);
    await tester.pumpTestApp(
      child: Scaffold(body: ApplyControls(control: control)),
    );
    owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(control.state.hasWork, isTrue);
    expect(_visibleActions(), containsAll(["Discard", "Retry", "Apply"]));
    expect(find.text("Name is unavailable"), findsWidgets);
    expect(
      owner.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
  });

  testWidgets(
    "Apply is hidden when clean, appears for edits, and hides after revert or acceptance",
    (tester) async {
      final owner = _owner();
      final control = owner.bindControl();
      addTearDown(control.dispose);
      addTearDown(owner.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: control)),
      );
      expect(find.text("Apply"), findsNothing);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      expect(find.text("Apply"), findsOneWidget);
      expect(find.text("Discard"), findsOneWidget);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Saved"));
      await tester.pump();
      expect(find.text("Apply"), findsNothing);
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(find.text("Apply"), findsNothing);
      expect(
        owner.document.confirmedValue,
        skir.DataValue.wrapStringValue("Draft"),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
    },
  );
  testWidgets(
    "unknown delivery retains disabled Apply and never offers unsupported retry",
    (tester) async {
      var sends = 0;
      final owner = _owner(
        commit: (_) async {
          sends++;
          throw TimeoutException("Lost response");
        },
      );
      final control = owner.bindControl();
      addTearDown(control.dispose);
      addTearDown(owner.dispose);
      await tester.pumpTestApp(
        child: Scaffold(body: ApplyControls(control: control)),
      );
      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text("Retry"), findsNothing);
      expect(find.text("Discard"), findsNothing);
      expect(find.text("Refresh"), findsOneWidget);
      expect(sends, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      owner.dispose();
    },
  );
  testWidgets("Apply acts only on its bound owner", (tester) async {
    final first = _owner();
    final other = _owner();
    final control = first.bindControl();
    addTearDown(control.dispose);
    addTearDown(first.dispose);
    addTearDown(other.dispose);
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    other.update(editorRootPath, skir.DataValue.wrapStringValue("Other"));
    await tester.pumpTestApp(
      child: Scaffold(body: ApplyControls(control: control)),
    );
    await tester.tap(find.text("Apply"));
    await tester.pumpAndSettle();
    expect(first.hasWork, isFalse);
    expect(other.hasWork, isTrue);
    expect(other.document.revision, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    other.dispose();
  });
}

List<String> _visibleActions() => find
    .byWidgetPredicate(
      (widget) =>
          widget is Text &&
          const {
            "Apply",
            "Discard",
            "Retry",
            "Refresh",
            "Discard later edits",
          }.contains(widget.data),
    )
    .evaluate()
    .map((element) => (element.widget as Text).data!)
    .toList();
