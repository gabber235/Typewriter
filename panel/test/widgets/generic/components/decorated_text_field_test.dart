import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/generic/components/decorated_text_field.dart";

import "../../../test_utils.dart";

class TestIntent extends Intent {
  const TestIntent();
}

void main() {
  group("DecoratedTextField - focus & actions", () {
    testWidgets("DismissIntent moves focus away from the inner TextField",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);

      final context = tester.element(find.byType(TextField));
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
    });
  });

  group("DecoratedTextField - callbacks & editing lifecycle", () {
    testWidgets("onChanged is called when text changes", (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      String? changedValue;
      final controller = TextEditingController();
      final widget = DecoratedTextField(
        focusNode: innerFocus,
        controller: controller,
        onChanged: (v) => changedValue = v,
      );

      await tester.pumpTestApp(child: widget);

      await tester.enterText(find.byType(TextField), "hello");
      await tester.pump();

      expect(controller.text, "hello");
      expect(changedValue, "hello");
    });

    testWidgets("onSubmitted and onDone are called when submitting",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      String? submitted;
      String? done;
      final controller = TextEditingController();
      final widget = DecoratedTextField(
        focusNode: innerFocus,
        controller: controller,
        onSubmitted: (v) => submitted = v,
        onDone: (v) => done = v,
      );

      await tester.pumpTestApp(child: widget);

      await tester.enterText(find.byType(TextField), "abc");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submitted, "abc");
      expect(done, "abc");
    });

    testWidgets("onDone is called when losing focus", (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final otherFocus = FocusNode(debugLabel: "other");
      String? done;
      final controller = TextEditingController(text: "xyz");
      final widget = Column(
        children: [
          DecoratedTextField(
            focusNode: innerFocus,
            controller: controller,
            onDone: (v) => done = v,
          ),
          TextField(focusNode: otherFocus),
        ],
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(innerFocus.hasFocus, isTrue);

      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(innerFocus.hasFocus, isFalse);
      expect(done, "xyz");
    });
  });

  group("DecoratedTextField - shortcuts interaction (baseline)", () {
    testWidgets("SingleActivator(letter) is blocked, text still types",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyH): const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();

      expect(fired, 0);
    });

    testWidgets("CharacterActivator(letter) is blocked, text still types",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        const CharacterActivator("h"): const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();

      expect(fired, 0);
    });

    testWidgets(
        "LogicalKeySet(single non-modifier key) is blocked, text still types",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.keyH): const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.pump();

      expect(fired, 0);
    });

    testWidgets(
        "SingleActivator with Ctrl is NOT blocked and triggers shortcut",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyH, control: true):
            const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(fired, 1);
    });

    testWidgets(
        "SingleActivator with Shift is blocked and does NOT trigger shortcut",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyH, shift: true):
            const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(fired, 0);
    });

    testWidgets("Escape shortcut dismisses inner focus", (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");

      final shortcuts = <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
    });

    testWidgets(r"CharacterActivator(\) is blocked, text still types",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var fired = 0;

      final shortcuts = <ShortcutActivator, Intent>{
        const CharacterActivator(r"\"): const TestIntent(),
      };
      final actions = <Type, Action<Intent>>{
        TestIntent: CallbackAction<TestIntent>(onInvoke: (_) => fired++),
      };

      final widget = DecoratedTextField(
        focusNode: innerFocus,
      );

      await tester.pumpTestApp(
        child: widget,
        shortcuts: shortcuts,
        actions: actions,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
      await tester.pump();

      expect(fired, 0);
    });
  });
}
