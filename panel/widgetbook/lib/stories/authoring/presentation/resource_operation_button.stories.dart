import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(
  name: "Availability and labels",
  type: ResourceOperationButton,
)
Widget resourceOperationButtonStory(BuildContext context) {
  final enabled = context.knobs.boolean(
    label: "Operation enabled",
    initialValue: true,
  );
  final longLabel = context.knobs.boolean(
    label: "Long extension label",
    initialValue: false,
  );
  final emphasis = context.knobs.object.dropdown(
    label: "Emphasis",
    options: OperationEmphasis.values,
    labelBuilder: (value) => switch (value) {
      OperationEmphasis.filled => "Filled",
      OperationEmphasis.outline => "Outline",
      OperationEmphasis.flat => "Flat",
    },
  );
  final destructive = context.knobs.boolean(label: "Destructive tone");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 260,
        child: ResourceOperationButton(
          emphasis: emphasis,
          presentation: skir.OperationPresentation(
            inspector: skir.OperationInspector.shown,
            emphasis: switch (emphasis) {
              OperationEmphasis.filled => skir.OperationEmphasis.filled,
              OperationEmphasis.outline => skir.OperationEmphasis.outline,
              OperationEmphasis.flat => skir.OperationEmphasis.flat,
            },
            shortcut: destructive ? skir.OperationShortcut.delete : null,
            label: longLabel
                ? "Generate dialogue variations for this selection"
                : destructive
                ? "Delete"
                : "Link with duplicate",
            description: "Run the declared operation for this selection",
            icon: destructive ? "mdi:delete-outline" : "mdi:link-variant-plus",
            tone: destructive
                ? skir.HeaderActionTone.destructive
                : skir.HeaderActionTone.neutral,
            group: destructive
                ? skir.OperationGroup.destructive
                : skir.OperationGroup.organize,
            order: 0,
            confirmation: null,
          ),
          disabledReason: enabled ? null : "The inverse reference is full",
          command: ActionShortcut(
            id: "story_resource_operation",
            label: "Run operation",
            description: "Run the declared operation for this selection",
            activators: const [],
            priority: 0,
            show: false,
            run: ActionRun.press((_) {}),
          ),
        ),
      ),
    ),
  );
}
