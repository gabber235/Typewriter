import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The hour, minute and second fields of the date popup; a valid entry
/// changes the time shown below.
@widgetbook.UseCase(name: "Time of day", type: DateTimeFields)
Widget dateTimeFieldsUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    DateTimeFieldsStory(
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 320, "Narrow": 200}),
    ),
  ),
);

/// Keeps the time [DateTimeFields] edit and shows it below.
class DateTimeFieldsStory extends HookWidget {
  const DateTimeFieldsStory({
    required this.enabled,
    required this.width,
    super.key,
  });

  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final value = useState(DateTime.utc(2026, 9, 16, 14, 30, 5));
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          DateTimeFields(
            value: value.value,
            enabled: enabled,
            onChanged: (next) => value.value = next,
          ),
          Text(value.value.toEditorText(includeDate: false, includeTime: true)),
        ],
      ),
    );
  }
}
