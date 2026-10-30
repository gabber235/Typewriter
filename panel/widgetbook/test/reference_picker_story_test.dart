import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/reference_picker.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("reference choices explain why a page cannot be chosen", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(referencePickerUseCase))!;

    await panel.tapOn(find.text("Choose a reference"));

    expect(panel.search.result("Welcome").isShown, isTrue);
    expect(panel.search.result("Create Sequence").isShown, isTrue);
    expect(panel.shows("This page does not accept a sequence entry"), isTrue);
  });

  testWidgets("without an incompatible page or creation only the compatible "
      "page is offered", (tester) async {
    final panel = (await tester.pumpStory(
      referencePickerUseCase,
      knobs: {
        "Incompatible destination": "false",
        "Allow target creation": "false",
      },
    ))!;

    await panel.tapOn(find.text("Choose a reference"));

    expect(panel.search.result("Welcome").isShown, isTrue);
    expect(panel.search.result("Overview").isShown, isFalse);
    expect(panel.search.result("Create Sequence").isShown, isFalse);
  });

  testWidgets("an Entry joins the compatible current page without asking", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      resourceCreationFlowUseCase,
      knobs: {"Compatible current page": "true"},
    ))!;

    await panel.tapOn(find.text("Create Entry"));

    await panel.eventually(
      () => expect(panel.world.requireRealm.saves, hasLength(1)),
    );
    expect(panel.search.result("Create Page").isShown, isFalse);
  });

  testWidgets("an Entry without a page creates its Page and Book on the way", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(resourceCreationFlowUseCase))!;

    await panel.tapOn(find.text("Create Entry"));
    await panel.search.result("Create Page").tap();
    expect(panel.world.requireRealm.saves, isEmpty);
    await panel.search.result("Create Book").tap();

    await panel.eventually(
      () => expect(panel.world.requireRealm.saves, hasLength(1)),
    );
  });
}
