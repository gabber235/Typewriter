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

  testWidgets("conditional removal restores normal mode after teardown", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    late StateSetter setState;
    var visible = true;

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, update) {
          setState = update;
          if (!visible) return const SizedBox.shrink();
          return InputFieldContainer(
            controller: controller,
            child: Focus(
              focusNode: controller.inputFocusNode,
              child: const SizedBox.shrink(),
            ),
          );
        },
      ),
    );

    controller.requestInputFocus();
    await tester.pump();
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    setState(() => visible = false);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("stale unregister preserves a replacement registration", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const SizedBox.shrink());
    final coordinator = tester.container().read(
      inputFieldModeCoordinatorProvider,
    );
    final staleInput = FocusNode();
    final staleSurrounding = FocusNode();
    final currentInput = FocusNode();
    final currentSurrounding = FocusNode();
    addTearDown(staleInput.dispose);
    addTearDown(staleSurrounding.dispose);
    addTearDown(currentInput.dispose);
    addTearDown(currentSurrounding.dispose);

    final unregisterStale = coordinator.register(
      id: "shared",
      inputFocusNode: staleInput,
      surroundingFocusNode: staleSurrounding,
    );
    final unregisterCurrent = coordinator.register(
      id: "shared",
      inputFocusNode: currentInput,
      surroundingFocusNode: currentSurrounding,
    );
    coordinator.begin("shared");

    unregisterStale();
    await tester.pump();
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    unregisterCurrent();
    await tester.pump();
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("deferred unregister is safe after provider disposal", (
    tester,
  ) async {
    await tester.pumpTestApp(child: const SizedBox.shrink());
    final coordinator = tester.container().read(
      inputFieldModeCoordinatorProvider,
    );
    final input = FocusNode();
    final surrounding = FocusNode();
    addTearDown(input.dispose);
    addTearDown(surrounding.dispose);
    final unregister = coordinator.register(
      id: "disposed",
      inputFocusNode: input,
      surroundingFocusNode: surrounding,
    );
    coordinator.begin("disposed");

    unregister();
    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
  });
}
