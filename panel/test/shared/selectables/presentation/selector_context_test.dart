import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const record = "Record selection";
  final target = TestSelectableIdentifier(id: "target");
  final other = TestSelectableIdentifier(id: "other");

  final gestures = {
    ContextGesture.secondaryClick: TargetPlatform.android,
    ContextGesture.longPress: TargetPlatform.android,
    ContextGesture.controlClick: TargetPlatform.macOS,
  };
  for (final MapEntry(key: gesture, value: platform) in gestures.entries) {
    testWidgets("${gesture.name} selects the target before its action runs", (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final card = SelectionCard(target);
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(card),
      );

      final menu = await panel.item("Target").contextMenu(gesture: gesture);
      expect(panel.container.read(selectionProvider), [target]);
      await menu.choose(record);

      expect(card.operation.executions, [
        [target],
      ]);
      expect(panel.focused, "Target");
      debugDefaultTargetPlatformOverride = null;
    });
  }

  for (final member in [true, false]) {
    testWidgets(
      "a context action on ${member ? "a selected" : "an unselected"} target "
      "${member ? "keeps" : "replaces"} the selection",
      (tester) async {
        final card = SelectionCard(target);
        final panel = await tester.pumpPanel(
          const [],
          at: PanelLocation.component(card),
        );
        panel.container.read(selectionProvider.notifier).selectAll([
          other,
          if (member) target,
        ]);

        final menu = await panel.item("Target").contextMenu();
        await menu.choose(record);

        expect(card.operation.executions, [
          [if (member) other, target],
        ]);
      },
    );
  }

  testWidgets("the menu stays at the pointer when selecting moves the target", (
    tester,
  ) async {
    final card = SelectionCard(target, moveOnSelection: true);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );
    final before = panel.item("Target").rect.center;

    final menu = await panel.item("Target").contextMenu();

    expect(panel.item("Target").rect.center.dx, greaterThan(before.dx + 100));
    final entry = menu.rectOf(record);
    expect(entry.left, lessThan(before.dx + 30));
    expect(entry.right, greaterThan(before.dx));
    await menu.choose(record);
    expect(card.operation.executions, [
      [target],
    ]);
  });

  testWidgets("a tap and the space key toggle the selection without a menu", (
    tester,
  ) async {
    final card = SelectionCard(target);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    await panel.item("Target").select();
    expect(panel.container.read(selectionProvider), [target]);
    expect(panel.menu.isOpen, isFalse);
    await panel.press(LogicalKeyboardKey.space);
    expect(panel.container.read(selectionProvider), isEmpty);
    await panel.press(LogicalKeyboardKey.space);
    expect(panel.container.read(selectionProvider), [target]);

    expect(card.operation.executions, isEmpty);
  });

  testWidgets("a target without available actions opens no menu", (
    tester,
  ) async {
    final card = SelectionCard(target)..operation.available = false;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    final menu = await panel.item("Target").contextMenu();

    expect(menu.isOpen, isFalse);
    expect(panel.container.read(selectionProvider), [target]);
    expect(panel.focused, "Target");
  });

  testWidgets("a loading target opens its menu once it resolved", (
    tester,
  ) async {
    final deferred = DeferredSelectableIdentifier(id: "target");
    final card = SelectionCard(deferred);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    final menu = await panel.item("Target").contextMenu();
    expect(menu.isOpen, isFalse);
    deferred.resolve(panel);
    await panel.settle();
    await menu.choose(record);

    expect(card.operation.executions, [
      [deferred],
    ]);
  });

  testWidgets("removing the actions cancels a menu waiting for its target", (
    tester,
  ) async {
    final deferred = DeferredSelectableIdentifier(id: "target");
    final card = SelectionCard(deferred);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    final menu = await panel.item("Target").contextMenu();
    card.actionsEnabled.value = false;
    await panel.settle();
    deferred.resolve(panel);
    await panel.settle();

    expect(menu.isOpen, isFalse);
    expect(card.operation.executions, isEmpty);
  });

  testWidgets("an unavailable target never opens a menu", (tester) async {
    final deferred = DeferredSelectableIdentifier(id: "target")
      ..result = AsyncError(StateError("Unavailable"), StackTrace.current);
    final card = SelectionCard(deferred);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    final menu = await panel.item("Target").contextMenu();

    expect(menu.isOpen, isFalse);
    expect(card.operation.executions, isEmpty);
  });

  testWidgets("selecting something else cancels a menu waiting for its "
      "target", (tester) async {
    final deferred = DeferredSelectableIdentifier(id: "target");
    final card = SelectionCard(deferred);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(card),
    );

    final menu = await panel.item("Target").contextMenu();
    panel.container.read(selectionProvider.notifier).selectAll([other]);
    deferred.resolve(panel);
    await panel.settle();

    expect(panel.container.read(selectionProvider), [other]);
    expect(menu.isOpen, isFalse);
  });

  testWidgets("closing the target while its menu waits opens nothing", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SelectionCard(DeferredSelectableIdentifier(id: "target")),
      ),
    );

    await panel.item("Target").contextMenu();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
