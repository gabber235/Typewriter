import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
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
    await tester.tap(find.text("Choose organization"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Organization"));
    await tester.pumpAndSettle();
    expect(find.text("Organization"), findsNothing);

    expect(find.text("Choose organization"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
