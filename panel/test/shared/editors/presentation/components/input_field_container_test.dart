import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/test_utils.dart";

void main() {
  testWidgets("dismiss is handled only while the inner input is focused", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    var inputDismissals = 0;
    var ancestorDismissals = 0;

    await tester.pumpTestApp(
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => ancestorDismissals++,
          ),
        },
        child: InputFieldContainer(
          controller: controller,
          onDismiss: () => inputDismissals++,
          child: Focus(
            key: const ValueKey("input"),
            focusNode: controller.inputFocusNode,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    controller.requestSurroundingFocus();
    await tester.pump();
    Actions.invoke(
      tester.element(find.byKey(const ValueKey("input"))),
      const DismissIntent(),
    );

    expect(inputDismissals, 0);
    expect(ancestorDismissals, 1);

    controller.requestInputFocus();
    await tester.pump();
    Actions.invoke(
      tester.element(find.byKey(const ValueKey("input"))),
      const DismissIntent(),
    );

    expect(inputDismissals, 1);
    expect(ancestorDismissals, 1);
  });

  testWidgets("endInteraction only ends the controller interaction", (
    tester,
  ) async {
    final first = InputFieldController();
    final second = InputFieldController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpTestApp(
      child: Column(
        children: [
          InputFieldContainer(
            controller: first,
            child: Focus(
              key: const ValueKey("first"),
              focusNode: first.inputFocusNode,
              child: const SizedBox.shrink(),
            ),
          ),
          InputFieldContainer(
            controller: second,
            child: Focus(
              key: const ValueKey("second"),
              focusNode: second.inputFocusNode,
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );

    first.surroundingFocusNode.requestFocus();
    await tester.pump();
    Actions.invoke(
      tester.element(find.byKey(const ValueKey("first"))),
      const ActivateIntent(),
    );
    await tester.pump();

    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    second.endInteraction();
    await tester.pump();

    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    first.endInteraction();
    await tester.pump();

    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });
}
