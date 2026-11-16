import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One day of the calendar in each of its states: picked, under keyboard
/// focus, outside the shown month, or ruled out by the caller.
@widgetbook.UseCase(name: "States", type: DateTimeDayCell)
Widget dateTimeDayCellUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: "Selected");
  final focused = context.knobs.boolean(label: "Focused");
  final inMonth = context.knobs.boolean(label: "In month", initialValue: true);
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 40,
        child: DateTimeDayCell(
          date: DateTime.utc(2026, 9, 16),
          selected: selected,
          focused: focused,
          inMonth: inMonth,
          enabled: enabled,
          onPressed: (_) {},
        ),
      ),
    ),
  );
}
