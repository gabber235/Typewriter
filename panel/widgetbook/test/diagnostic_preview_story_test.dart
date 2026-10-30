import "package:flutter_test/flutter_test.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/diagnostic_preview.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("a dragged card still reports its failed operation", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(diagnosticPreviewUseCase))!;

    expect(panel.shows("Village Market"), isTrue);
    expect(find.bySemanticsLabel("Presentation error"), findsOneWidget);
  });

  testWidgets("a dragged card after a save carries no feedback", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      diagnosticPreviewUseCase,
      knobs: {"Last operation": "Saved"},
    ))!;

    expect(panel.shows("Village Market"), isTrue);
    expect(find.bySemanticsLabel("Presentation error"), findsNothing);
  });
}
