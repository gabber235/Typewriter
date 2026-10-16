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
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: 260,
        child: ResourceOperationButton(
          label: longLabel
              ? "Generate dialogue variations for this selection"
              : "Link with duplicate",
          description: "Create a copy and link this resource to it",
          disabledReason: enabled ? null : "The inverse reference is full",
          onInvoke: () {},
        ),
      ),
    ),
  );
}
