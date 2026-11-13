import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The calendar of the date popup: it pages through months, switches to a
/// month or year grid from its header, and picks a day. A caller can rule
/// out days, here every weekend.
@widgetbook.UseCase(name: "Pick a day", type: DateTimeCalendar)
Widget dateTimeCalendarUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    DateTimeCalendarStory(
      weekdaysOnly: context.knobs.boolean(label: "Weekdays only"),
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 320, "Narrow": 260}),
    ),
  ),
);

/// Keeps the day a [DateTimeCalendar] picks and shows it below.
class DateTimeCalendarStory extends HookWidget {
  const DateTimeCalendarStory({
    required this.weekdaysOnly,
    required this.enabled,
    required this.width,
    super.key,
  });

  final bool weekdaysOnly;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final value = useState(DateTime.utc(2026, 9, 16, 14, 30));
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          DateTimeCalendar(
            value: value.value,
            enabled: enabled,
            selectableDate: weekdaysOnly
                ? (date) => date.weekday <= DateTime.friday
                : null,
            onChanged: (next) => value.value = next,
          ),
          Text(value.value.toEditorText(includeDate: true, includeTime: false)),
        ],
      ),
    );
  }
}
