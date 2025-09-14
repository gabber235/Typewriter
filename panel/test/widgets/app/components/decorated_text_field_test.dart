import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/insert_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";

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
}
