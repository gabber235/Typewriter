import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("dismiss is handled only while the inner input is focused", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    var inputDismissals = 0;
    var ancestorDismissals = 0;
    var ancestorCancellations = 0;

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) => ancestorDismissals++,
            ),
            CancelIntent: CallbackAction<CancelIntent>(
              onInvoke: (_) => ancestorCancellations++,
            ),
          },
          child: InputFieldContainer(
            controller: controller,
            onDismiss: () => inputDismissals++,
            child: Focus(
              focusNode: controller.inputFocusNode,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    controller.requestSurroundingFocus();
    await tester.pump();
    Actions.invoke(controller.inputFocusNode.context!, const DismissIntent());

    expect(inputDismissals, 0);
    expect(ancestorDismissals, 1);

    controller.requestInputFocus();
    await tester.pump();
    Actions.invoke(controller.inputFocusNode.context!, const DismissIntent());

    expect(inputDismissals, 1);
    expect(ancestorDismissals, 1);

    Actions.invoke(controller.inputFocusNode.context!, const CancelIntent());

    expect(inputDismissals, 1);
    expect(ancestorCancellations, 1);
  });

  testWidgets("endInteraction only ends the controller interaction", (
    tester,
  ) async {
    final first = InputFieldController();
    final second = InputFieldController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          children: [
            InputFieldContainer(
              controller: first,
              child: Focus(
                focusNode: first.inputFocusNode,
                child: const SizedBox.shrink(),
              ),
            ),
            InputFieldContainer(
              controller: second,
              child: Focus(
                focusNode: second.inputFocusNode,
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );

    first.surroundingFocusNode.requestFocus();
    await tester.pump();
    Actions.invoke(first.inputFocusNode.context!, const ActivateIntent());
    await tester.pump();

    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    second.endInteraction();
    await tester.pump();

    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    first.endInteraction();
    await tester.pump();

    expect(
      panel.container.read(currentInteractionModeProvider),
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

    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        StatefulBuilder(
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
      ),
    );

    controller.requestInputFocus();
    await tester.pump();
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    setState(() => visible = false);
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("stale unregister preserves a replacement registration", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox.shrink()),
    );
    final coordinator = panel.container.read(inputFieldModeCoordinatorProvider);
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
      panel.container.read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );

    unregisterCurrent();
    await tester.pump();
    expect(
      panel.container.read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("deferred unregister is safe after provider disposal", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(SizedBox.shrink()),
    );
    final coordinator = panel.container.read(inputFieldModeCoordinatorProvider);
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
