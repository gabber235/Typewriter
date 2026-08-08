import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/test_utils.dart";

void main() {
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
