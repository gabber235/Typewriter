import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [InputIconButton] at the end of a query field; hover it for its
/// tooltip. Without Enabled it cannot be pressed.
@widgetbook.UseCase(name: "Default", type: InputIconButton)
Widget inputIconButtonUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      StoryCard(
        width: 320,
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Expanded(child: Text("ada")),
            InputIconButton(
              icon: const Icon(Icons.close),
              tooltip: "Clear search",
              onPressed: enabled ? () {} : null,
            ),
          ],
        ),
      ),
    ),
  );
}
