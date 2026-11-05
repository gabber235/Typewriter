import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "a drag carries the selection only when it starts on a selected resource",
    () {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final primary = fixture.drag.primary;
      final second = AuthoringResourceIdentifier.inScope(
        fixture.scope,
        fixture.second,
      );
      final foreign = second.copyWith(
        realmId: skir.RecordId(
          table: fixture.scope.realmId.table,
          key: skir.RecordIdKey.wrapString("other"),
        ),
      );
      expect(
        ResourceDrag.forSelection(
          primary: primary,
          selection: [second, foreign],
        ).subjects,
        [fixture.source],
      );
      expect(
        ResourceDrag.forSelection(
          primary: primary,
          selection: [second, primary, foreign],
        ).subjects,
        [fixture.source, fixture.second],
      );
    },
  );

  testWidgets(
    "only the bound resource's own link fields receive dropped resources",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      // The editor is bound to the second entry; the target entry's field is
      // a reference preview of another resource nested in that editor.
      final panel = await fixture.showGraph(
        tester,
        bound: fixture.second,
        linkFields: {
          "Own triggers": fixture.second,
          "Previewed triggers": fixture.target,
        },
      );
      List<skir.ResourceId> triggers(skir.ResourceId resource) => [
        for (final link in fixture.workspace.document.links)
          if (link.contract == fixture.triggerRelation &&
              link.first == resource)
            link.second,
      ];

      await panel.dragItem(
        "entry:source",
        panel.item("Previewed triggers").rect,
      );
      expect(triggers(fixture.target), isEmpty);

      await panel.dragItem("entry:source", panel.item("Own triggers").rect);
      expect(triggers(fixture.second), [fixture.source]);
      expect(triggers(fixture.target), isEmpty);
    },
  );

  testWidgets("clicking a node selects it and moves focus onto it", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture(secondSource: true);
    final panel = await fixture.showGraph(tester);

    await panel.item("entry:source").select();

    expect(panel.focused, "entry:source");
    expect(panel.item("entry:source").isMarkedSelected, isTrue);
    expect(panel.item("entry:second").isMarkedSelected, isFalse);
    expect(panel.container.read(selectionProvider), [fixture.drag.primary]);
  });

  testWidgets(
    "a node dropped on another node links them instead of moving it",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final moves = <List<GraphMoveCommitPayload>>[];
      final panel = await fixture.showGraph(tester, onMove: moves.add);

      await panel.dragItem("entry:source", panel.item("entry:second").rect);

      // One link field fits, so no source field is asked for.
      expect(panel.shows("Choose source field"), isFalse);
      expect(moves, isEmpty);
      final links = fixture.workspace.document.links.where(
        (link) => link.contract == fixture.triggerRelation,
      );
      expect(
        [for (final link in links) (link.first, link.second)],
        [(fixture.source, fixture.second)],
      );
    },
  );

  testWidgets("a read only node keeps Delete from reaching the surface and "
      "cannot be dragged", (tester) async {
    final fixture = AuthoredGraphFixture();
    var inheritedDeletes = 0;
    final panel = await fixture.showGraph(
      tester,
      readOnly: true,
      sidebar: true,
      actions: {
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (_) {
            inheritedDeletes++;
            return null;
          },
        ),
      },
    );

    await panel.item("entry:source").select();
    await panel.press(LogicalKeyboardKey.delete);
    await panel.dragItem(
      "entry:source",
      tester.getRect(find.text("Destination")),
    );

    expect(inheritedDeletes, 0);
    expect(fixture.workspace.document.resource(fixture.source), isNotNull);
    expect(
      fixture.workspace.document.relations.children[fixture.page],
      contains(fixture.source),
    );
    expect(fixture.workspace.hasPendingWork, isFalse);
  });

  testWidgets("a sidebar drop moves the dragged resource to its new owner", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final panel = await fixture.showGraph(tester, sidebar: true);

    await panel.dragItem(
      "entry:source",
      tester.getRect(find.text("Destination")),
    );

    expect(
      fixture.workspace.document.relations.children[fixture.destination],
      contains(fixture.source),
    );
    expect(
      fixture.workspace.document.relations.children[fixture.page] ?? const [],
      isNot(contains(fixture.source)),
    );
  });

  testWidgets("Shift M and Shift R move and resize the focused node with the "
      "arrow keys", (tester) async {
    final fixture = AuthoredGraphFixture();
    final moves = <List<GraphMoveCommitPayload>>[];
    final resizes = <List<GraphResizeCommitPayload>>[];
    final panel = await fixture.showGraph(
      tester,
      onMove: moves.add,
      onResize: resizes.add,
    );
    await panel.item("entry:source").select();

    await panel.pressShifted(LogicalKeyboardKey.keyM);
    await panel.press(LogicalKeyboardKey.arrowRight);
    await panel.press(LogicalKeyboardKey.escape);
    await panel.pressShifted(LogicalKeyboardKey.keyR);
    await panel.press(LogicalKeyboardKey.arrowRight);
    await panel.press(LogicalKeyboardKey.escape);

    expect([for (final move in moves) move.single.x], [1]);
    expect([for (final resize in resizes) resize.single.width], [5]);
    expect(panel.focused, "entry:source");
  });

  testWidgets("an active sidebar drag cannot outlive source mutation access", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final readOnly = ValueNotifier(false);
    addTearDown(readOnly.dispose);
    final panel = await fixture.showGraph(
      tester,
      sidebar: true,
      readOnlySource: readOnly,
    );
    final gesture = await tester.startGesture(
      panel.item("entry:source").rect.center,
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    readOnly.value = true;
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text("Destination")));
    await tester.pump();
    await gesture.up();
    await panel.settle();

    expect(
      fixture.workspace.document.relations.children[fixture.page],
      contains(fixture.source),
    );
    expect(
      fixture.workspace.document.relations.children[fixture.destination],
      isNot(contains(fixture.source)),
    );
  });

  testWidgets(
    "keyboard context actions choose a destination and restore focus",
    (tester) async {
      final fixture = AuthoredGraphFixture();
      final panel = await fixture.showGraph(tester);
      await panel.item("entry:source").select();

      await panel.pressShifted(LogicalKeyboardKey.f10);
      await panel.menu.chooseWithKeyboard("Move to");
      await panel.submitOperationForm("destination", fixture.destination.value);

      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
      expect(panel.shows("Submit"), isFalse);
      expect(panel.focused, "entry:source");
    },
  );

  testWidgets(
    "keyboard activation selects nodes and menu cancellation returns focus",
    (tester) async {
      final fixture = AuthoredGraphFixture(secondSource: true);
      final panel = await fixture.showGraph(tester);
      final source = AuthoringResourceIdentifier.inScope(
        fixture.scope,
        fixture.source,
      );
      final second = AuthoringResourceIdentifier.inScope(
        fixture.scope,
        fixture.second,
      );
      await panel.item("entry:source").select();

      await panel.press(LogicalKeyboardKey.tab);
      expect(panel.focused, "entry:second");
      await panel.press(LogicalKeyboardKey.enter);
      expect(panel.container.read(selectionProvider), [second]);
      await panel.pressShifted(LogicalKeyboardKey.tab);
      expect(panel.focused, "entry:source");
      await panel.pressShifted(LogicalKeyboardKey.enter);
      expect(panel.container.read(selectionProvider).toSet(), {source, second});

      await panel.pressShifted(LogicalKeyboardKey.f10);
      expect(panel.menu.entries, contains("Link with"));
      await panel.menu.dismiss();
      expect(panel.menu.isOpen, isFalse);
      expect(panel.focused, "entry:source");
    },
  );

  testWidgets("keyboard Link with submits typed transient target input", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final panel = await fixture.showGraph(tester);
    await panel.item("entry:source").select();

    await panel.pressShifted(LogicalKeyboardKey.f10);
    await panel.menu.chooseWithKeyboard("Link with");
    await panel.submitOperationForm("target", fixture.target.value);

    final link = fixture.workspace.document.links.singleWhere(
      (link) => link.contract == fixture.triggerRelation,
    );
    expect((link.first, link.second), (fixture.source, fixture.target));
  });
}
