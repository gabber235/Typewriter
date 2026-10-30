import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_resource_editor.stories.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/authored_type_picker.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("creating a page offers every concrete page type", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(authoredTypePickerUseCase))!;

    for (final type in ["Sequence", "Static", "Scene", "Manifest"]) {
      expect(panel.shows(type), isTrue, reason: type);
    }
    expect(panel.shows("Page"), isFalse);
  });

  testWidgets("searching narrows the page types and a choice closes the "
      "picker", (tester) async {
    final panel = (await tester.pumpStory(authoredTypePickerUseCase))!;

    await panel.field("Search resource types").enter("Sta");
    expect(panel.shows("Static"), isTrue);
    expect(panel.shows("Sequence"), isFalse);

    await panel.tapOn(find.text("Static"));
    expect(panel.shows("Static"), isFalse);
  });

  testWidgets("an unfinished title is filled through the inspector", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(
      authoredResourceEditorUseCase,
      knobs: {"Title": "Unfinished"},
    ))!;
    expect(panel.field("Title").value, isEmpty);

    await panel.field("Title").enter("Meet the mayor");

    expect(
      panel.working
          .resource(messageFixture().resource)!
          .authoredField("title")!
          .authoredPayload,
      skir.DataValue.wrapStringValue("Meet the mayor"),
    );
  });
}
