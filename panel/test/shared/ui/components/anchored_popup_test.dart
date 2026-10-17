import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final dismissal in ["button", "escape", "outside", "back"]) {
    testWidgets("popup restores focus after $dismissal dismissal", (
      tester,
    ) async {
      final trigger = FocusNode();
      addTearDown(trigger.dispose);
      await tester.pumpTestApp(
        child: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: AnchoredPopup(
              targetAnchor: Alignment.bottomRight,
              popupAnchor: Alignment.topRight,
              builder: (context, show) => TextButton(
                focusNode: trigger,
                onPressed: show,
                child: const Text("Open"),
              ),
              popupBuilder: (context, close) => SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TextField(autofocus: true),
                    TextButton(
                      onPressed: close,
                      child: const Text("Close popup"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      trigger.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      await tester.pumpAndSettle();
      expect(find.text("Close popup"), findsOneWidget);
      expect(trigger.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(trigger.hasFocus, isFalse);

      switch (dismissal) {
        case "button":
          await tester.tap(find.text("Close popup"));
        case "escape":
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case "outside":
          await tester.tapAt(const Offset(10, 500));
        case "back":
          await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text("Close popup"), findsNothing);
      expect(find.text("Open"), findsOneWidget);
      expect(trigger.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("preview preserves typing and promotion retains content", (
    tester,
  ) async {
    final popup = AnchoredPopupController();
    final editor = FocusNode();
    final controller = TextEditingController();
    addTearDown(popup.dispose);
    addTearDown(editor.dispose);
    addTearDown(controller.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: editor, controller: controller),
            AnchoredPopup(
              controller: popup,
              builder: (context, show) =>
                  TextButton(onPressed: show, child: const Text("Inbox")),
              popupBuilder: (context, close) =>
                  const SizedBox(width: 300, child: TextField(autofocus: true)),
            ),
          ],
        ),
      ),
    );
    editor.requestFocus();
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text("Inbox")));
    await tester.pumpAndSettle();
    expect(editor.hasFocus, isTrue);
    expect(find.byKey(const ValueKey("popup barrier")), findsNothing);
    final field = find.byType(TextField).last;
    final element = tester.element(field);
    await tester.enterText(find.byType(TextField).first, "still editing");
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    expect(tester.element(field), same(element));
    expect(editor.hasFocus, isFalse);
    expect(find.byKey(const ValueKey("popup barrier")), findsOneWidget);
    await tester.enterText(field, "persistent filter");
    expect(controller.text, "still editing");
    popup.close();
    await tester.pumpAndSettle();
    expect(editor.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets("hover crosses the popup gap and closes after leaving", (
    tester,
  ) async {
    final popup = AnchoredPopupController();
    addTearDown(popup.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: AnchoredPopup(
            controller: popup,
            offset: const Offset(0, 16),
            builder: (context, show) =>
                TextButton(onPressed: show, child: const Text("Open")),
            popupBuilder: (context, close) =>
                const SizedBox(width: 300, height: 200, child: Text("Preview")),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text("Open")));
    await tester.pumpAndSettle();
    expect(popup.presentation, PopupPresentation.preview);
    final trigger = tester.getRect(find.byType(TextButton));
    await mouse.moveTo(Offset(trigger.center.dx, trigger.bottom + 8));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Preview"), findsOneWidget);
    await mouse.moveTo(tester.getCenter(find.text("Preview")));
    await tester.pump(const Duration(seconds: 1));
    expect(popup.presentation, PopupPresentation.preview);
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(popup.presentation, PopupPresentation.closed);
    expect(find.text("Preview"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("Escape dismisses hover without changing editor focus", (
    tester,
  ) async {
    var editorDismissals = 0;
    final editor = FocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          editorDismissals++;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    addTearDown(editor.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: editor),
            AnchoredPopup(
              builder: (context, show) =>
                  TextButton(onPressed: show, child: const Text("Open")),
              popupBuilder: (context, close) => const Text("Preview"),
            ),
          ],
        ),
      ),
    );
    editor.requestFocus();
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text("Open")));
    await tester.pumpAndSettle();
    expect(find.text("Preview"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Preview"), findsNothing);
    expect(editor.hasFocus, isTrue);
    expect(editorDismissals, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(editorDismissals, 1);
    await mouse.moveTo(const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text("Open")));
    await tester.pumpAndSettle();
    expect(find.text("Preview"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the first preview click focuses before invoking its action", (
    tester,
  ) async {
    final popup = AnchoredPopupController();
    addTearDown(popup.dispose);
    PopupPresentation? invoked;
    await tester.pumpTestApp(
      child: Scaffold(
        body: AnchoredPopup(
          controller: popup,
          builder: (context, show) =>
              TextButton(onPressed: show, child: const Text("Inbox")),
          popupBuilder: (context, close) => TextButton(
            onPressed: () => invoked = popup.presentation,
            child: const Text("Navigate to issue"),
          ),
        ),
      ),
    );
    popup.preview();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Navigate to issue"));
    await tester.pumpAndSettle();
    expect(invoked, PopupPresentation.focused);
    expect(tester.takeException(), isNull);
  });

  testWidgets("scope dismissal does not restore prior editor focus", (
    tester,
  ) async {
    final popup = AnchoredPopupController();
    final editor = FocusNode();
    addTearDown(popup.dispose);
    addTearDown(editor.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: editor),
            AnchoredPopup(
              controller: popup,
              builder: (context, show) =>
                  TextButton(onPressed: show, child: const Text("Inbox")),
              popupBuilder: (context, close) =>
                  const TextField(autofocus: true),
            ),
          ],
        ),
      ),
    );
    editor.requestFocus();
    await tester.pump();
    popup.openFocused();
    await tester.pumpAndSettle();
    popup.close(reason: PopupCloseReason.scopeChanged);
    await tester.pumpAndSettle();
    expect(editor.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets("removing an open anchor removes the popup and its history", (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: visible,
          builder: (context, value, _) => value
              ? AnchoredPopup(
                  builder: (context, show) =>
                      TextButton(onPressed: show, child: const Text("Open")),
                  popupBuilder: (context, close) => const Text("Popup"),
                )
              : const Text("Removed"),
        ),
      ),
    );
    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    visible.value = false;

    await tester.pumpAndSettle();
    expect(find.text("Popup"), findsNothing);
    expect(find.text("Removed"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("selector selection closes the popup without popping the page", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Scaffold(
        body: SelectorPopup<String>(
          asyncValue: const AsyncData(["Organization"]),
          buttonBuilder: (_) => const Text("Choose organization"),
          contentBuilder: (items, selected, onSelect) => TextButton(
            onPressed: () => onSelect(items.single),
            child: Text(items.single),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text("Choose organization")));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey("popup barrier")), findsNothing);
    await tester.tap(find.text("Organization"));
    await tester.pumpAndSettle();
    expect(find.text("Organization"), findsNothing);

    expect(find.text("Choose organization"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("mobile selector opens a sheet only after activation", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpTestApp(
      child: Scaffold(
        body: SelectorPopupWithSelection<String>(
          itemsAsync: const AsyncData(["Book"]),
          selectedAsync: const AsyncData("Book"),
          buttonBuilder: (_) => const Text("Choose book"),
          contentBuilder: (items, selected, onSelect) => TextButton(
            onPressed: () => onSelect(items.single),
            child: Text(items.single),
          ),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(300, 500));
    await mouse.moveTo(tester.getCenter(find.text("Choose book")));
    await tester.pumpAndSettle();
    expect(find.text("Book"), findsNothing);
    await tester.tap(find.text("Choose book"));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text("Book"));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text("Choose book"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
