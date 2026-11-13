import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The month or year grid the calendar header opens: the arrow keys move
/// through it and a press or Enter picks the item.
@widgetbook.UseCase(
  name: "Months and years",
  type: DateTimeCalendarSelectionGrid,
)
Widget dateTimeCalendarSelectionGridUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    DateTimeCalendarSelectionGridStory(
      years:
          context.knobs.object.segmented(
            label: "Items",
            options: const ["Months", "Years"],
            initialOption: "Months",
          ) ==
          "Years",
      width: context.knobs.width(const {"Popup": 320, "Narrow": 220}),
    ),
  ),
);

/// Keeps the item a [DateTimeCalendarSelectionGrid] picks.
class DateTimeCalendarSelectionGridStory extends HookWidget {
  const DateTimeCalendarSelectionGridStory({
    required this.years,
    required this.width,
    super.key,
  });

  final bool years;
  final double width;

  @override
  Widget build(BuildContext context) {
    final selected = useState(years ? 2026 : 9);
    useEffect(() {
      selected.value = years ? 2026 : 9;
      return null;
    }, [years]);
    final items = years
        ? [
            for (var year = 2016; year < 2028; year++)
              (value: year, label: "$year"),
          ]
        : [
            for (final (index, name) in calendarMonthNames.indexed)
              (value: index + 1, label: name),
          ];
    return SizedBox(
      width: width,
      child: DateTimeCalendarSelectionGrid(
        label: years ? "Year" : "Month",
        items: items,
        selectedValue: selected.value,
        columns: 3,
        onSelected: (value) => selected.value = value,
      ),
    );
  }
}
