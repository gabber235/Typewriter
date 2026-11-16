import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The header above the calendar: the arrows step by month, year or group
/// of years as the view asks, and the month and year buttons open their
/// grids. September is the longest month name.
@widgetbook.UseCase(name: "Views", type: DateTimeCalendarHeader)
Widget dateTimeCalendarHeaderUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    DateTimeCalendarHeaderStory(
      view: context.knobs.object.segmented(
        label: "View",
        options: DateTimeCalendarView.values,
        initialOption: DateTimeCalendarView.days,
        labelBuilder: (view) => switch (view) {
          DateTimeCalendarView.days => "Days",
          DateTimeCalendarView.months => "Months",
          DateTimeCalendarView.years => "Years",
        },
      ),
      width: context.knobs.width(const {"Popup": 320, "Narrow": 220}),
    ),
  ),
);

/// Keeps the month and view a [DateTimeCalendarHeader] moves.
class DateTimeCalendarHeaderStory extends HookWidget {
  const DateTimeCalendarHeaderStory({
    required this.view,
    required this.width,
    super.key,
  });

  final DateTimeCalendarView view;
  final double width;

  @override
  Widget build(BuildContext context) {
    final month = useState(DateTime.utc(2026, 9));
    final shown = useState(view);
    useEffect(() {
      shown.value = view;
      return null;
    }, [view]);
    final step = switch (shown.value) {
      DateTimeCalendarView.days => 1,
      DateTimeCalendarView.months => 12,
      DateTimeCalendarView.years => 144,
    };
    void move(int months) => month.value = DateTime.utc(
      month.value.year,
      month.value.month + months,
    );
    void toggle(DateTimeCalendarView target) => shown.value =
        shown.value == target ? DateTimeCalendarView.days : target;
    return SizedBox(
      width: width,
      child: DateTimeCalendarHeader(
        visibleMonth: month.value,
        view: shown.value,
        onPrevious: () => move(-step),
        onNext: () => move(step),
        onMonthPickerRequested: () => toggle(DateTimeCalendarView.months),
        onYearPickerRequested: () => toggle(DateTimeCalendarView.years),
      ),
    );
  }
}
