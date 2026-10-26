import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

import "../application/selection_test_support.dart";

void main() {
  const record = "Record selection";
  const target = MockSelectableIdentifier("target");
  const other = MockSelectableIdentifier("other");

  Future<PanelDriver> pump(WidgetTester tester, _Card card) =>
      tester.pumpPanel(const [], at: PanelLocation.component(card));

  List<SelectableIdentifier> selection(PanelDriver panel) =>
      panel.container.read(selectionProvider);

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
      final card = _Card(target);
      final panel = await pump(tester, card);

      final menu = await panel.item("Target").contextMenu(gesture: gesture);
      expect(selection(panel), [target]);
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
        final card = _Card(target);
        final panel = await pump(tester, card);
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
    final card = _Card(target, moveOnSelection: true);
    final panel = await pump(tester, card);
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
    final card = _Card(target);
    final panel = await pump(tester, card);

    await panel.item("Target").select();
    expect(selection(panel), [target]);
    expect(panel.menu.isOpen, isFalse);
    await panel.press(LogicalKeyboardKey.space);
    expect(selection(panel), isEmpty);
    await panel.press(LogicalKeyboardKey.space);
    expect(selection(panel), [target]);

    expect(card.operation.executions, isEmpty);
  });

  testWidgets("a target without available actions opens no menu", (
    tester,
  ) async {
    final card = _Card(target)..operation.available = false;
    final panel = await pump(tester, card);

    final menu = await panel.item("Target").contextMenu();

    expect(menu.isOpen, isFalse);
    expect(selection(panel), [target]);
    expect(panel.focused, "Target");
  });

  testWidgets("a loading target opens its menu once it resolved", (
    tester,
  ) async {
    final deferred = _DeferredIdentifier("target");
    final card = _Card(deferred);
    final panel = await pump(tester, card);

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
    final deferred = _DeferredIdentifier("target");
    final card = _Card(deferred);
    final panel = await pump(tester, card);

    final menu = await panel.item("Target").contextMenu();
    card.actionsEnabled.value = false;
    await panel.settle();
    deferred.resolve(panel);
    await panel.settle();

    expect(menu.isOpen, isFalse);
    expect(card.operation.executions, isEmpty);
  });

  testWidgets("an unavailable target never opens a menu", (tester) async {
    final deferred = _DeferredIdentifier("target")
      ..result = AsyncError(StateError("Unavailable"), StackTrace.current);
    final card = _Card(deferred);
    final panel = await pump(tester, card);

    final menu = await panel.item("Target").contextMenu();

    expect(menu.isOpen, isFalse);
    expect(card.operation.executions, isEmpty);
  });

  testWidgets("selecting something else cancels a menu waiting for its "
      "target", (tester) async {
    final deferred = _DeferredIdentifier("target");
    final card = _Card(deferred);
    final panel = await pump(tester, card);

    final menu = await panel.item("Target").contextMenu();
    panel.container.read(selectionProvider.notifier).selectAll([other]);
    deferred.resolve(panel);
    await panel.settle();

    expect(selection(panel), [other]);
    expect(menu.isOpen, isFalse);
  });

  testWidgets("closing the target while its menu waits opens nothing", (
    tester,
  ) async {
    final panel = await pump(tester, _Card(_DeferredIdentifier("target")));

    await panel.item("Target").contextMenu();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

/// A selectable card offering one recorded action, as features build them.
final class _Card extends HookWidget {
  _Card(this.target, {this.moveOnSelection = false});

  final MockSelectableIdentifier target;
  final bool moveOnSelection;
  final operation = _RecordingOperation();

  /// Whether the card's actions are registered.
  final actionsEnabled = ValueNotifier(true);

  @override
  Widget build(BuildContext context) {
    final focus = useFocusNode();
    useEffect(() => actionsEnabled.dispose, const []);
    return Consumer(
      builder: (context, ref, _) {
        final selected = ref.watch(isSelectedProvider(target));
        return ValueListenableBuilder(
          valueListenable: actionsEnabled,
          builder: (context, enabled, _) => SelectionOperationsRoot(
            source: RegisteredSelectionOperations([if (enabled) operation]),
            child: Align(
              alignment: moveOnSelection && selected
                  ? Alignment.centerRight
                  : Alignment.center,
              child: Selector(
                selectableId: target,
                focusNode: focus,
                builder: (selected, focused, hovered) => const SizedBox(
                  width: 180,
                  height: 80,
                  child: Text("Target"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A target whose selectable resolves when the test says so.
class _DeferredIdentifier extends MockSelectableIdentifier {
  _DeferredIdentifier(super.id);

  AsyncValue<Selectable<MockSelectableIdentifier>> result =
      const AsyncLoading();

  @override
  AsyncValue<Selectable<MockSelectableIdentifier>> create(Ref ref) => result;

  void resolve(PanelDriver panel) {
    result = AsyncData(MockSelectable(this));
    panel.container.invalidate(selectedProvider);
  }
}

class _RecordingOperation extends SelectionOperation {
  final executions = <List<SelectableIdentifier>>[];
  bool available = true;

  @override
  String get name => "Record selection";

  @override
  String get description => "Record the resolved action targets";

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      available && selection.isNotEmpty;

  @override
  void executeOn(WidgetRef ref) {
    executions.add(
      ref.read(selectedProvider).requireValue.map((item) => item.id).toList(),
    );
  }

  @override
  MenuItem menuItem(WidgetRef ref) =>
      MenuItem(label: name, onPressed: () => executeOn(ref));

  @override
  Widget inspectorButton(List<Selectable> selection) => const SizedBox.shrink();
}
