import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [EmptyScreen] in its full and small sizes, with or without its action.
@widgetbook.UseCase(name: "Default", type: EmptyScreen)
Widget emptyScreenUseCase(BuildContext context) {
  final small = context.knobs.boolean(label: "Small", initialValue: false);
  final action = context.knobs.boolean(label: "Action", initialValue: false);
  return Story(
    const [],
    at: PanelLocation.component(
      EmptyScreen(
        title: "No join codes yet",
        small: small,
        buttonText: action ? "Create join code" : null,
        onPressed: action ? () {} : null,
      ),
    ),
  );
}
