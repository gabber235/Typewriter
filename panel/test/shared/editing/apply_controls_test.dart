import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _debounce = Duration(milliseconds: 250);

void main() {
  testWidgets(
    "automatic value controls stay hidden before submission and while awaiting acknowledgement",
    (tester) async {
      final saving = AutosavingOwner();
      final owner = saving.owner;
      final panel = await tester.pumpControls(
        ApplyControls(control: boundControl(owner)),
      );

      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await tester.pump();
      expect(owner.hasWork, isTrue);
      expect(saving.sends, 0);
      expect(panel.applyControls.actions, isEmpty);

      await tester.pump(_debounce);
      await tester.pump();
      expect(saving.sends, 1);
      expect(panel.applyControls.actions, isEmpty);

      saving.reply.complete(savedTextResult("Draft"));
      await panel.settle();
      expect(owner.hasWork, isFalse);
      expect(panel.applyControls.actions, isEmpty);
      expect(saving.sends, 1);
    },
  );

  testWidgets(
    "selection of healthy automatic owners keeps shared controls hidden",
    (tester) async {
      final savings = [AutosavingOwner(), AutosavingOwner()];
      final owners = [for (final saving in savings) saving.owner];
      final selection = EditSelectionControl([
        for (final owner in owners) boundControl(owner),
      ]);
      addTearDown(selection.dispose);
      final panel = await tester.pumpControls(
        ApplyControls(control: selection),
      );

      for (final owner in owners) {
        owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      }
      await tester.pump();
      expect(owners.map((owner) => owner.hasWork), everyElement(isTrue));
      expect(panel.applyControls.actions, isEmpty);

      await tester.pump(_debounce);
      await tester.pump();
      expect(savings.map((saving) => saving.sends), [1, 1]);
      expect(panel.applyControls.actions, isEmpty);

      for (final saving in savings) {
        saving.reply.complete(savedTextResult("Draft"));
      }
      await panel.settle();
      expect(owners.map((owner) => owner.hasWork), everyElement(isFalse));
      expect(panel.applyControls.actions, isEmpty);
    },
  );

  testWidgets("automatic group panels keep their label and review hidden", (
    tester,
  ) async {
    final saving = AutosavingOwner();
    final owner = saving.owner;
    final panel = await tester.pumpControls(
      EditingGroupPanel(
        workspace: owner.workspace,
        id: owner.groupId,
        review: () => const Text("Review"),
      ),
    );

    void expectHidden() {
      expect(panel.shows("Edit value"), isFalse);
      expect(panel.shows("View changes"), isFalse);
      expect(panel.applyControls.actions, isEmpty);
    }

    owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await tester.pump();
    expect(owner.hasWork, isTrue);
    expectHidden();

    await tester.pump(_debounce);
    await tester.pump();
    expect(saving.sends, 1);
    expectHidden();

    saving.reply.complete(savedTextResult("Draft"));
    await panel.settle();
    expect(owner.hasWork, isFalse);
    expectHidden();
  });

  testWidgets(
    "combined manual work keeps existing Apply rules while another member saves",
    (tester) async {
      final session = ScopedWorkSession();
      addTearDown(session.dispose);
      final saving = AutosavingOwner(session: session);
      final automatic = saving.owner;
      var manualSends = 0;
      final manual = savedTextOwner(
        session: session,
        commit: (capture) async {
          manualSends++;
          return TypedMutationResult.success(
            revision: capture.expectedRevision + 1,
            value: capture.rootValue,
          );
        },
      );
      final selection = EditSelectionControl([
        boundControl(automatic),
        boundControl(manual),
      ]);
      addTearDown(selection.dispose);
      final panel = await tester.pumpControls(
        ApplyControls(control: selection),
      );

      automatic.update(
        editorRootPath,
        skir.DataValue.wrapStringValue("Automatic"),
      );
      manual.update(editorRootPath, skir.DataValue.wrapStringValue("Manual"));
      await tester.pump(_debounce);
      await tester.pump();
      expect(saving.sends, 1);
      expect(manualSends, 0);
      expect(panel.applyControls.actions, contains("Apply"));
      expect(panel.applyControls.isEnabled("Apply"), isFalse);

      saving.reply.complete(savedTextResult("Automatic"));
      await panel.settle();
      expect(automatic.hasWork, isFalse);
      expect(manual.hasWork, isTrue);
      expect(panel.applyControls.isEnabled("Apply"), isTrue);

      await panel.applyControls.press("Apply");
      expect(saving.sends, 1);
      expect(manualSends, 1);
      expect(manual.hasWork, isFalse);
      expect(panel.applyControls.actions, isEmpty);
    },
  );

  testWidgets("rejected automatic value edits expose recovery controls", (
    tester,
  ) async {
    final owner = savedTextOwner(
      policy: EditorCommitPolicy.autosaveChanges,
      commit: (_) async => invalidMutation("Name is unavailable"),
    );
    final panel = await tester.pumpControls(
      ApplyControls(control: boundControl(owner)),
    );

    owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
    await tester.pump(_debounce);
    await panel.settle();

    expect(
      panel.applyControls.actions,
      containsAll(["Discard", "Retry", "Apply"]),
    );
    expect(panel.shows("Name is unavailable"), isTrue);
    expect(
      owner.value(editorRootPath).valueOrNull,
      skir.DataValue.wrapStringValue("Draft"),
    );
  });

  testWidgets(
    "Apply is hidden when clean, appears for edits, and hides after revert or acceptance",
    (tester) async {
      final owner = savedTextOwner();
      final panel = await tester.pumpControls(
        ApplyControls(control: boundControl(owner)),
      );
      expect(panel.applyControls.actions, isEmpty);

      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await panel.settle();
      expect(panel.applyControls.actions, ["Discard", "Apply"]);

      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Saved"));
      await panel.settle();
      expect(panel.applyControls.actions, isEmpty);

      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await panel.settle();
      await panel.applyControls.press("Apply");
      expect(panel.applyControls.actions, isEmpty);
      expect(
        owner.document.confirmedValue,
        skir.DataValue.wrapStringValue("Draft"),
      );
    },
  );

  testWidgets(
    "unknown delivery retains disabled Apply and never offers unsupported retry",
    (tester) async {
      var sends = 0;
      final owner = savedTextOwner(
        commit: (_) async {
          sends++;
          throw TimeoutException("Lost response");
        },
      );
      final panel = await tester.pumpControls(
        ApplyControls(control: boundControl(owner)),
      );

      owner.update(editorRootPath, skir.DataValue.wrapStringValue("Draft"));
      await panel.settle();
      await panel.applyControls.press("Apply");

      expect(panel.applyControls.actions, ["Refresh", "Apply"]);
      expect(panel.applyControls.isEnabled("Apply"), isFalse);
      expect(sends, 1);
    },
  );

  testWidgets("Apply acts only on its bound owner", (tester) async {
    final first = savedTextOwner();
    final other = savedTextOwner();
    final control = boundControl(first);
    first.update(editorRootPath, skir.DataValue.wrapStringValue("First"));
    other.update(editorRootPath, skir.DataValue.wrapStringValue("Other"));
    final panel = await tester.pumpControls(ApplyControls(control: control));

    await panel.applyControls.press("Apply");

    expect(first.hasWork, isFalse);
    expect(other.hasWork, isTrue);
    expect(other.document.revision, 1);
  });
}
