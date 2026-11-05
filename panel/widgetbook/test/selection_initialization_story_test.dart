import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/adaptive_choice_control.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a sole choice is chosen without asking", (tester) async {
    await tester.pumpStory(
      adaptiveChoiceControlUseCase,
      knobs: {"Choices": "1"},
    );

    expect(find.text("Paper"), findsOneWidget);
  });

  testWidgets("a preferred default is chosen among many choices", (
    tester,
  ) async {
    await tester.pumpStory(
      adaptiveChoiceControlUseCase,
      knobs: {"Choices": "6", "Preferred default": "true"},
    );

    expect(find.text("Velocity"), findsOneWidget);
    expect(find.text("Paper"), findsNothing);
  });
}
