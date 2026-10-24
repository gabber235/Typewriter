import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

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
  final variant = context.knobs.object.dropdown(
    label: "Button variant",
    options: [
      skir.ButtonVariant.filled,
      skir.ButtonVariant.outlined,
      skir.ButtonVariant.text,
    ],
    labelBuilder: (value) => switch (value) {
      skir.ButtonVariant.filled => "Filled",
      skir.ButtonVariant.outlined => "Outlined",
      _ => "Text",
    },
  );
  final destructive = context.knobs.boolean(label: "Destructive tone");
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: 260,
        child: ResourceOperationButton(
          presentation: skir.OperationPresentation(
            showInInspector: true,
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
            variant: variant,
            group: destructive
                ? skir.OperationGroup.destructive
                : skir.OperationGroup.organize,
            order: 0,
            confirmation: null,
          ),
          disabledReason: enabled ? null : "The inverse reference is full",
          onInvoke: () {},
        ),
      ),
    ),
  );
}
