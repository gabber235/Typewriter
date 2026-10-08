import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "../application/selection_test_support.dart";

void main() {
  for (final gesture in ["secondary", "long press", "control click"]) {
    testWidgets("$gesture selects the clicked target before executing", (
      tester,
    ) async {
      if (gesture == "control click") {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
      }
      final h = _Harness();
      await h.pump(tester);
      await _activate(tester, gesture);
      expect(tester.takeException(), isNull);
      expect(h.container.read(selectionProvider), [h.target]);
      await tester.tap(find.text("Record selection"));
      await tester.pumpAndSettle();
      expect(h.operation.executions, [
        [h.target],
      ]);
      expect(h.focus.hasFocus, isTrue);
      if (gesture == "control click") {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
  for (final member in [true, false]) {
    testWidgets(
      "context action handles existing selection membership $member",
      (tester) async {
        final h = _Harness();
        await h.pump(tester);
        h.container.read(selectionProvider.notifier).selectAll([
          h.other,
          if (member) h.target,
        ]);
        await tester.pumpAndSettle();
        await _activate(tester, "secondary");
        await tester.tap(find.text("Record selection"));
        await tester.pumpAndSettle();
        expect(h.operation.executions, [
          [if (member) h.other, h.target],
        ]);
      },
    );
  }
  testWidgets("menu stays at the pointer when selection moves the target", (
    tester,
  ) async {
    final h = _Harness(moveOnSelection: true);
    await h.pump(tester);
    final before = tester.getCenter(find.byKey(const Key("target card")));
    await _activate(tester, "secondary");
    final after = tester.getCenter(find.byKey(const Key("target card")));
    expect(after.dx, greaterThan(before.dx + 100));
    final action = tester.getRect(find.text("Record selection"));
    expect(action.left, lessThan(before.dx + 30));
    expect(action.right, greaterThan(before.dx));
    await tester.tap(find.text("Record selection"));
    await tester.pumpAndSettle();
    expect(h.operation.executions, [
      [h.target],
    ]);
  });

  testWidgets("ordinary tap and keyboard activation retain toggle semantics", (
    tester,
  ) async {
    final h = _Harness();
    await h.pump(tester);
    await tester.tap(find.byKey(const Key("target card")));
    await tester.pumpAndSettle();
    expect(h.container.read(selectionProvider), [h.target]);
    expect(find.text("Record selection"), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.container.read(selectionProvider), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(h.container.read(selectionProvider), [h.target]);
    expect(h.operation.executions, isEmpty);
  });

  testWidgets(
    "resolved target without available actions does not open a menu",
    (tester) async {
      final h = _Harness();
      h.operation.available = false;
      await h.pump(tester);
      await _activate(tester, "secondary");
      expect(tester.takeException(), isNull);
      expect(h.container.read(selectionProvider), [h.target]);
      expect(h.focus.hasFocus, isTrue);
      expect(find.text("Record selection"), findsNothing);
    },
  );

  testWidgets("loading target opens only after resolution", (tester) async {
    final target = _DeferredIdentifier("target");
    final h = _Harness(target: target);
    await h.pump(tester);
    await _activate(tester, "secondary");
    expect(tester.takeException(), isNull);
    expect(find.text("Record selection"), findsNothing);
    target.result = AsyncData(MockSelectable(target, target.value));
    h.container.invalidate(selectedProvider);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Record selection"));
    await tester.pumpAndSettle();
    expect(h.operation.executions, [
      [target],
    ]);
  });
  testWidgets("removing the action registry cancels a waiting menu", (
    tester,
  ) async {
    final target = _DeferredIdentifier("target");
    final h = _Harness(target: target);
    await h.pump(tester);
    await _activate(tester, "secondary");
    expect(tester.takeException(), isNull);
    h.registryEnabled.value = false;
    await tester.pumpAndSettle();
    target.result = AsyncData(MockSelectable(target, target.value));
    h.container.invalidate(selectedProvider);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("Record selection"), findsNothing);
    expect(h.operation.executions, isEmpty);
  });

  testWidgets("unavailable target never opens a menu", (tester) async {
    final target = _DeferredIdentifier("target")
      ..result = AsyncError(StateError("Unavailable"), StackTrace.current);
    final h = _Harness(target: target);
    await h.pump(tester);
    await _activate(tester, "secondary");
    expect(tester.takeException(), isNull);
    expect(find.text("Record selection"), findsNothing);
    expect(h.operation.executions, isEmpty);
  });
  testWidgets("later unrelated selection cancels a pending context action", (
    tester,
  ) async {
    final target = _DeferredIdentifier("target");
    final h = _Harness(target: target);
    await h.pump(tester);
    await _activate(tester, "secondary");
    expect(tester.takeException(), isNull);
    h.container.read(selectionProvider.notifier).selectAll([h.other]);
    target.result = AsyncData(MockSelectable(target, target.value));
    h.container.invalidate(selectedProvider);
    await tester.pumpAndSettle();
    expect(h.container.read(selectionProvider), [h.other]);
    expect(find.text("Record selection"), findsNothing);
  });
  testWidgets("disposing a pending context action cannot open a menu", (
    tester,
  ) async {
    final h = _Harness(target: _DeferredIdentifier("target"));
    await h.pump(tester);
    await _activate(tester, "secondary");
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _activate(WidgetTester tester, String gesture) async {
  final item = find.byKey(const Key("target card"));
  switch (gesture) {
    case "secondary":
      await tester.tap(item, buttons: kSecondaryMouseButton);
    case "long press":
      await tester.longPress(item);
    case "control click":
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(item);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness({MockSelectableIdentifier? target, this.moveOnSelection = false})
    : target = target ?? MockSelectableIdentifier("target");
  final MockSelectableIdentifier target;
  final bool moveOnSelection;
  final other = MockSelectableIdentifier("other");
  final focus = FocusNode();
  final operation = _RecordingOperation();
  final registryEnabled = ValueNotifier(true);
  late ProviderContainer container;
  Future<void> pump(WidgetTester tester) async {
    addTearDown(focus.dispose);
    addTearDown(registryEnabled.dispose);
    await tester.pumpTestApp(
      child: Consumer(
        builder: (context, ref, child) {
          container = ProviderScope.containerOf(context);
          final selected = ref.watch(isSelectedProvider(target));
          return ValueListenableBuilder(
            valueListenable: registryEnabled,
            builder: (context, enabled, child) {
              return SelectionOperationsRoot(
                operations: [if (enabled) operation],
                child: Align(
                  alignment: moveOnSelection && selected
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: Selector(
                    selectableId: target,
                    focusNode: focus,
                    builder: (selected, focused, hovered) => const SizedBox(
                      key: Key("target card"),
                      width: 180,
                      height: 80,
                      child: Text("Target"),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DeferredIdentifier extends MockSelectableIdentifier {
  _DeferredIdentifier(super.id);
  AsyncValue<Selectable<MockSelectableIdentifier>> result =
      const AsyncLoading();
  @override
  AsyncValue<Selectable<MockSelectableIdentifier>> create(Ref ref) => result;
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
