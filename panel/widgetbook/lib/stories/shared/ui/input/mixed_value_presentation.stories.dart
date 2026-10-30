import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [MixedValueMessage] the inspector shows when the selected resources
/// hold different values for one field.
@widgetbook.UseCase(name: "Default", type: MixedValueMessage)
Widget mixedValueMessageUseCase(BuildContext context) {
  return const Story(
    [],
    at: PanelLocation.component(
      SizedBox(width: 320, child: MixedValueMessage()),
    ),
  );
}
