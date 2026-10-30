import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("omitted scalar children edit their stable source items inline", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.textList,
    );

    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester);
    expect(visibleFieldValues(), ["Arrival", "Discovery", "Return"]);
    expect(find.tooltip("Expand"), findsNothing);
    await panel.fieldAt(0).type("Landing");
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.first,
    );
    expect(scenario.value.authoredItems!.first.value.authoredString, "Landing");
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "map key edits and width changes keep the row and the focused draft",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.scalarMap,
      );

      addTearDown(scenario.dispose);
      final stage = CollectionEditorStage();
      final panel = await scenario.show(tester, stage: stage);
      await panel.fieldAt(0).type("opening");
      final rows =
          (scenario.value.authoredPayload as skir.DataValue_mapValueWrapper)
              .value
              .rows;
      expect(rows.first.id, CollectionEditorScenario.first);
      expect(rows.first.key.authoredString, "opening");
      expect(rows.first.value.authoredString, "Arrival");
      stage.change(() => stage.width = 320);
      await panel.settle();
      expect(panel.fieldAt(0).isFocused, isTrue);
      expect(panel.fieldAt(0).value, "opening");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "authored titles refresh without collapsing or replacing inputs",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.authoredSteps,
      );

      addTearDown(scenario.dispose);
      final stage = CollectionEditorStage();
      final panel = await scenario.show(tester, stage: stage);
      await panel.tapOn(find.text("Arrival"));
      await panel.field("name").type("Landing");
      expect(find.text("Landing"), findsNWidgets(2));
      expect(panel.field("name").isFocused, isTrue);
      expect(visibleFieldValues(), ["Landing", "1"]);
      stage.change(() => stage.width = 320);
      await panel.settle();
      expect(panel.field("name").isFocused, isTrue);
      expect(panel.field("name").value, "Landing");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("a collection disclosure preserves an invalid numeric draft", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
    );

    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester);
    await panel.tapOn(find.text("Arrival").first);
    await panel.field("amount").type("-");
    expect(panel.field("amount").value, "-");
    await panel.tapOn(find.text("Arrival").first);
    expect(visibleTextFields(), isEmpty);
    await panel.tapOn(find.text("Arrival").first);
    expect(panel.field("amount").value, "-");
    expect(
      scenario.value.authoredItems!.first.value
          .authoredField("amount")!
          .authoredInteger,
      BigInt.one,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "fallback disclosure follows source identity through keyboard movement",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.fallbackSteps,
      );

      addTearDown(scenario.dispose);
      final panel = await scenario.show(tester);
      expect(find.text("Item 1"), findsOneWidget);
      expect(find.text("Item 2"), findsOneWidget);
      await panel.tapOn(find.text("Item 1"));
      await tester.tap(find.tooltip("Reorder item 1"));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await panel.settle();
      expect(scenario.value.authoredItems!.map((item) => item.id), [
        CollectionEditorScenario.second,
        CollectionEditorScenario.first,
      ]);
      // The moved row keeps its disclosure open and its handle keeps focus.
      expect(panel.field("name").value, "Arrival");
      expect(panel.holdsFocus(find.tooltip("Reorder item 2")), isTrue);
      expect(
        panel.field("name").rect.top,
        greaterThan(tester.getTopLeft(find.text("Item 2")).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "pointer dragging moves the source item through the real sequence",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.textList,
      );

      addTearDown(scenario.dispose);
      await scenario.show(tester);
      final first = find.tooltip("Reorder item 1");
      final last = find.tooltip("Reorder item 3");
      final destination = tester.getCenter(last) + const Offset(0, 80);
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pumpAndSettle();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        scenario.value.authoredItems!.last.id,
        CollectionEditorScenario.first,
      );
      expect(scenario.value.authoredItems!.map((item) => item.id).toSet(), {
        CollectionEditorScenario.first,
        CollectionEditorScenario.second,
        CollectionEditorScenario.third,
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "pointer reordering retains an expanded row's invalid numeric draft",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.authoredSteps,
      );

      addTearDown(scenario.dispose);
      final panel = await scenario.show(tester);
      await panel.tapOn(find.text("Arrival").first);
      await panel.field("amount").type("-");
      final first = find.tooltip("Reorder item 1");
      final last = find.tooltip("Reorder item 2");
      final destination = tester.getCenter(last) + const Offset(0, 80);
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 24));
      await tester.pumpAndSettle();
      await gesture.moveTo(destination);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        scenario.value.authoredItems!.last.id,
        CollectionEditorScenario.first,
      );
      // The dragged row's handle, now the last, takes focus from the draft.
      expect(panel.field("amount").isFocused, isFalse);
      expect(panel.holdsFocus(last), isTrue);
      expect(panel.field("amount").value, "-");
      expect(
        scenario.value.authoredItems!.last.value
            .authoredField("amount")!
            .authoredInteger,
        BigInt.one,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("default map children remove their containing source row", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.scalarMap,
    );

    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester);
    await panel.tapOn(find.tooltip("Remove row").first);
    final rows =
        (scenario.value.authoredPayload as skir.DataValue_mapValueWrapper)
            .value
            .rows;
    expect(rows, hasLength(1));
    expect(rows.single.id, CollectionEditorScenario.second);
    expect(rows.single.key.authoredString, "discovery");
    expect(rows.single.value.authoredString, "Discovery");
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "direct link Clear changes its relation and preserves sibling identity",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.directLinks,
      );

      addTearDown(scenario.dispose);
      final before = scenario.value.authoredItems!.toList();
      final unrelated = scenario.workspace.document
          .resource(compiledInheritanceBookId)!
          .authoredField("tags");
      final relations = scenario.workspace.document.links.length;
      final panel = await scenario.show(tester);
      expect(find.tooltip("Clear link"), findsNWidgets(2));
      expect(find.tooltip("Remove item"), findsNothing);
      await panel.tapOn(find.tooltip("Clear link").first);
      expect(scenario.value.authoredItems, hasLength(1));
      expect(scenario.value.authoredItems!.single.id, before.last.id);
      expect(scenario.workspace.document.links, hasLength(relations - 1));
      expect(
        scenario.workspace.document
            .resource(compiledInheritanceBookId)!
            .authoredField("tags"),
        unrelated,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("read only collections remain inspectable and cannot mutate", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
    );

    addTearDown(scenario.dispose);
    final before = scenario.value;
    final panel = await scenario.show(tester, readOnly: true);
    await panel.tapOn(find.text("Arrival"));
    expect(visibleFieldValues(), ["Arrival", "1"]);
    expect(panel.field("name").isReadOnly, isTrue);
    final mutations = find.tooltip(RegExp(r"^(Remove|Add) item$"));
    expect(mutations, findsWidgets);
    for (var index = 0; index < mutations.evaluate().length; index++) {
      expect(tester.getSemantics(mutations.at(index)).isEnabled, isFalse);
    }
    expect(scenario.value, before);
    expect(tester.takeException(), isNull);
  });

  for (final (name, example) in [
    (
      "cancelling authored removal leaves the actual draft untouched",
      CollectionEditorExample.authoredSteps,
    ),
    (
      "cancelling a nested collection header removal preserves both owners",
      CollectionEditorExample.nestedLists,
    ),
  ]) {
    testWidgets(name, (tester) async {
      final scenario = CollectionEditorScenario(
        example: example,
        confirmRemoval: true,
      );
      addTearDown(scenario.dispose);
      final panel = await scenario.show(tester);
      final before = scenario.value;
      await panel.tapOn(find.tooltip("Remove step").first);
      expect(panel.dialog.showing("Remove this step?"), isTrue);
      await panel.dialog.choose("Cancel", message: "Remove this step?");
      expect(scenario.value, before);
      expect(scenario.workspace.hasPendingWork, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("accepted delayed removal focuses the surviving row control", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.textList,
    );

    addTearDown(scenario.dispose);
    final (:panel, :gate, host: _, stage: _) = await scenario.showGated(tester);
    final remove = find.tooltip("Remove item").first;
    await panel.activateWithKeyboard(remove);
    await tester.pump();
    expect(scenario.value.authoredItems, hasLength(3));
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.second,
    );
    expect(panel.holdsFocus(find.tooltip("Remove item").first), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("removing the last row recovers to the preceding source row", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.textList,
    );

    addTearDown(scenario.dispose);
    final panel = await scenario.show(tester);
    await panel.activateWithKeyboard(find.tooltip("Remove item").last);
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.last.id,
      CollectionEditorScenario.second,
    );
    expect(panel.holdsFocus(find.tooltip("Remove item").last), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("removing the only row recovers to collection Add", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.textList,
    );

    addTearDown(scenario.dispose);
    scenario.keepFirst(1);
    final panel = await scenario.show(tester);
    await panel.activateWithKeyboard(find.tooltip("Remove item"));
    await tester.pumpAndSettle();
    expect(scenario.value.authoredItems, isEmpty);
    expect(panel.holdsFocus(find.tooltip("Add item")), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("rejected delayed removal retains the initiating control", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.textList,
    );

    addTearDown(scenario.dispose);
    final (:panel, :gate, host: _, stage: _) = await scenario.showGated(tester);
    final remove = find.tooltip("Remove item").first;
    await panel.activateWithKeyboard(remove);
    gate.complete(false);
    await tester.pumpAndSettle();
    expect(scenario.value.authoredItems, hasLength(3));
    expect(panel.holdsFocus(find.tooltip("Remove item").first), isTrue);
    expect(panel.holdsFocus(find.tooltip("Add item")), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "a removal retired by a host change plus source disappearance never recovers focus",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.textList,
      );

      addTearDown(scenario.dispose);
      final (:panel, :gate, :stage, host: _) = await scenario.showGated(tester);
      await panel.activateWithKeyboard(find.tooltip("Remove item").first);
      // A new host retires the removal still waiting on the old one.
      stage.change(() => stage.host = null);
      await tester.pump();
      final remaining = scenario.value.authoredItems!.skip(1).toList();
      scenario.binding
          .edit(
            label: "External row disappearance",
            apply: (edit) => edit.set(
              skir.ValueLocation(
                resource: CollectionEditorScenario.resource,
                path: CollectionEditorScenario.entriesPath,
              ),
              skir.DataValue.createNamed(
                actualType: scenario.value.authoredActualType!,
                payload: skir.DataValue.createListValue(items: remaining),
              ),
            ),
          )
          .requireAccepted();
      await tester.pump();
      await tester.pump();
      final frameworkFallback = FocusManager.instance.primaryFocus;
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(frameworkFallback));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a disposed collection cannot recover focus after delayed removal",
    (tester) async {
      final scenario = CollectionEditorScenario(
        example: CollectionEditorExample.textList,
      );

      addTearDown(scenario.dispose);
      final (:panel, :gate, :stage, host: _) = await scenario.showGated(tester);
      final nextPageFocus = FocusNode();
      addTearDown(nextPageFocus.dispose);
      await panel.activateWithKeyboard(find.tooltip("Remove item").first);
      // The user moves on to a page without the collection.
      stage.change(() => stage.next = TextField(focusNode: nextPageFocus));
      await tester.pump();
      nextPageFocus.requestFocus();
      await tester.pump();
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(nextPageFocus.hasFocus, isTrue);
      expect(scenario.value.authoredItems, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("focus moving within the pending row cancels removal recovery", (
    tester,
  ) async {
    final scenario = CollectionEditorScenario(
      example: CollectionEditorExample.authoredSteps,
    );

    addTearDown(scenario.dispose);
    final settlement = Completer<void>();
    final (:panel, :gate, :host, stage: _) = await scenario.showGated(
      tester,
      settlement: settlement,
    );
    await panel.tapOn(find.text("Arrival"));
    await panel.activateWithKeyboard(find.tooltip("Remove item").first);
    await tester.pump();
    await tester.tapAt(panel.field("name").rect.center);
    await tester.pump();
    expect(panel.field("name").isFocused, isTrue);
    gate.complete(true);
    expect(
      await host.sourceResult.future,
      isA<PortablePresentationWriteApplied>(),
    );
    await tester.pump();
    await tester.pump();
    expect(scenario.value.authoredItems, hasLength(1));
    final frameworkFallback = FocusManager.instance.primaryFocus;
    settlement.complete();
    await tester.pumpAndSettle();
    expect(
      scenario.value.authoredItems!.first.id,
      CollectionEditorScenario.second,
    );
    expect(FocusManager.instance.primaryFocus, same(frameworkFallback));
    expect(tester.takeException(), isNull);
  });
}
