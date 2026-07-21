import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../support/test_utils.dart";

class TestIntent extends Intent {
  const TestIntent();
}

void main() {
  group("DecoratedTextField - focus & actions", () {
    testWidgets("DismissIntent moves focus away from the inner TextField", (
      tester,
    ) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final widget = DecoratedTextField(focusNode: innerFocus);

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      final context = tester.element(find.byType(TextField));
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
    });

    testWidgets("autofocus starts in insert mode", (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final widget = DecoratedTextField(
        focusNode: innerFocus,
        autofocus: DecoratedTextFieldAutoFocus.textField,
      );

      await tester.pumpTestApp(child: widget);

      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );
    });

    testWidgets("DismissIntent bubbles up to parent action handlers", (
      tester,
    ) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      var parentDismissReceived = false;

      final widget = Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              parentDismissReceived = true;
              return null;
            },
          ),
        },
        child: DecoratedTextField(focusNode: innerFocus),
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);

      var context = FocusManager.instance.primaryFocus!.context!;
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(parentDismissReceived, isFalse);
      expect(innerFocus.hasPrimaryFocus, isFalse);

      /// Dismissing while we are focusing the surrounding focus should bubble up to the parent action handlers.
      context = FocusManager.instance.primaryFocus!.context!;
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(parentDismissReceived, isTrue);
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

    testWidgets("onSubmitted and onDone are called when submitting", (
      tester,
    ) async {
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
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(innerFocus.hasFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );

      expect(done, "xyz");
    });
  });

  group("DecoratedTextField - external value changes", () {
    testWidgets("focus is not lost when text value changes externally", (
      tester,
    ) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      late ValueNotifier<String> notifier;

      final widget = HookBuilder(
        builder: (context) {
          final state = useState("initial");
          notifier = state;
          return DecoratedTextField(focusNode: innerFocus, text: state.value);
        },
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      notifier.value = "updated externally";
      await tester.pumpAndSettle();

      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );
    });
  });
}
