import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/insert_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/normal_mode.dart";

import "package:typewriter_panel/widgets/app/components/dropdown.dart";

import "../../../test_utils.dart";

class TestIntent extends Intent {
  const TestIntent();
}

void main() {
  group("Dropdown - focus & actions", () {
    testWidgets("DismissIntent moves focus away from the inner DropdownMenu",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final widget = Dropdown<String>(
        focusNode: innerFocus,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: "A", label: "A"),
          DropdownMenuEntry(value: "B", label: "B"),
        ],
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      final context = tester.element(find.byType(DropdownMenu<String>));
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
    });
  });

  group("Dropdown - callbacks", () {
    testWidgets(
        "onSelected is called with correct value and controller updates",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final controller = TextEditingController();
      String? selected;

      final widget = HookBuilder(
        builder: (context) {
          final state = useState<String?>(null);
          return Dropdown<String>(
            focusNode: innerFocus,
            controller: controller,
            selected: state.value,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: "A", label: "Alpha"),
              DropdownMenuEntry(value: "B", label: "Beta"),
              DropdownMenuEntry(value: "C", label: "Gamma"),
            ],
            onSelected: (v) {
              selected = v;
              state.value = v;
            },
          );
        },
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      await tester.tap(find.text("Beta").last);
      await tester.pumpAndSettle();

      expect(selected, "B");

      final context = tester.element(find.byType(DropdownMenu<String>));
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(controller.text, "Beta");
      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
    });
  });

  group("Dropdown - controller resets", () {
    testWidgets("Controller resets to selected label when dismissing",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final controller = TextEditingController(text: "wrong");
      var firedSelected = 0;

      final widget = Dropdown<String>(
        focusNode: innerFocus,
        controller: controller,
        selected: "B",
        onSelected: (_) => firedSelected++,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: "A", label: "Alpha"),
          DropdownMenuEntry(value: "B", label: "Beta"),
          DropdownMenuEntry(value: "C", label: "Gamma"),
        ],
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );
      expect(firedSelected, 0);

      controller.text = "Alpha";
      await tester.pump();
      expect(controller.text, "Alpha");
      expect(firedSelected, 0);

      final context = tester.element(find.byType(DropdownMenu<String>));
      Actions.invoke(context, const DismissIntent());
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );

      expect(controller.text, "Beta");
      expect(firedSelected, 0);
    });

    testWidgets("Controller resets to selected label on programmatic unfocus",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final controller = TextEditingController(text: "wrong");
      var firedSelected = 0;

      final widget = Dropdown<String>(
        focusNode: innerFocus,
        controller: controller,
        selected: "B",
        onSelected: (_) => firedSelected++,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: "A", label: "Alpha"),
          DropdownMenuEntry(value: "B", label: "Beta"),
          DropdownMenuEntry(value: "C", label: "Gamma"),
        ],
      );

      await tester.pumpTestApp(child: widget);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      expect(innerFocus.hasPrimaryFocus, isTrue);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      expect(firedSelected, 0);

      controller.text = "Alpha";
      await tester.pump();
      expect(firedSelected, 0);
      expect(controller.text, "Alpha");

      innerFocus.unfocus();
      await tester.pump();

      expect(innerFocus.hasPrimaryFocus, isFalse);
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
      expect(controller.text, "Beta");
      expect(firedSelected, 0);
    });
  });

  group("Dropdown - selection interactions", () {
    testWidgets(
        "Selecting Gamma calls onSelected with 'C' and updates controller",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final controller = TextEditingController();
      String? selected = "A";
      String? lastSelected;

      final host = StatefulBuilder(
        builder: (context, setState) {
          return Dropdown<String>(
            focusNode: innerFocus,
            controller: controller,
            selected: selected,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: "A", label: "Alpha"),
              DropdownMenuEntry(value: "B", label: "Beta"),
              DropdownMenuEntry(value: "C", label: "Gamma"),
            ],
            onSelected: (v) {
              lastSelected = v;
              setState(() => selected = v);
            },
          );
        },
      );

      await tester.pumpTestApp(child: host);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      await tester.tap(find.text("Gamma").last);
      await tester.pumpAndSettle();

      expect(lastSelected, "C");
      expect(controller.text, "Gamma");
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
    });

    testWidgets(
        "Selecting Alpha from B calls onSelected with 'A' and updates controller",
        (tester) async {
      final innerFocus = FocusNode(debugLabel: "inner");
      final controller = TextEditingController();
      String? selected = "B";
      String? lastSelected;

      final host = StatefulBuilder(
        builder: (context, setState) {
          return Dropdown<String>(
            focusNode: innerFocus,
            controller: controller,
            selected: selected,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: "A", label: "Alpha"),
              DropdownMenuEntry(value: "B", label: "Beta"),
              DropdownMenuEntry(value: "C", label: "Gamma"),
            ],
            onSelected: (v) {
              lastSelected = v;
              setState(() => selected = v);
            },
          );
        },
      );

      await tester.pumpTestApp(child: host);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<InsertMode>(),
      );

      await tester.tap(find.text("Alpha").last);
      await tester.pumpAndSettle();

      expect(lastSelected, "A");
      expect(controller.text, "Alpha");
      expect(
        tester.container().read(currentInteractionModeProvider),
        isA<NormalMode>(),
      );
    });
  });
}
