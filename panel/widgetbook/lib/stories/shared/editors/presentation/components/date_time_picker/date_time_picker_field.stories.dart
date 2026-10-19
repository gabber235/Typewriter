import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Text and picker editing", type: DateTimePickerField)
Widget dateTimePickerFieldUseCase(
  BuildContext context,
) => DateTimePickerFieldStory(
  includeDate: context.knobs.boolean(label: "Include date", initialValue: true),
  includeTime: context.knobs.boolean(label: "Include time", initialValue: true),
  showPicker: context.knobs.boolean(
    label: "Show picker action",
    initialValue: true,
  ),
  bounded: context.knobs.boolean(
    label: "Limit to the event window",
    initialValue: false,
  ),
  mixed: context.knobs.boolean(label: "Mixed selection", initialValue: false),
  enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
  readOnly: context.knobs.boolean(label: "Read only", initialValue: false),
  width: context.knobs.double.slider(
    label: "Field width",
    initialValue: 420,
    min: 260,
    max: 640,
  ),
);

/// Binds a seasonal event start so typed drafts and picker choices report the
/// timestamp they would write.
class DateTimePickerFieldStory extends HookWidget {
  const DateTimePickerFieldStory({
    this.includeDate = true,
    this.includeTime = true,
    this.showPicker = true,
    this.bounded = false,
    this.mixed = false,
    this.enabled = true,
    this.readOnly = false,
    this.width = 420,
    super.key,
  });

  final bool includeDate;
  final bool includeTime;
  final bool showPicker;
  final bool bounded;
  final bool mixed;
  final bool enabled;
  final bool readOnly;
  final double width;

  @override
  Widget build(BuildContext context) {
    final bound = useState<DateTime?>(DateTime.utc(2026, 10, 31, 18, 30));
    final edited = useState(false);
    final showsMixed = mixed && !edited.value;
    final minimum = bounded ? DateTime.utc(2026, 10, 24) : null;
    final maximum = bounded ? DateTime.utc(2026, 11, 7, 23, 59, 59) : null;
    final showsDate = includeDate || !includeTime;
    void changed(DateTime next) {
      edited.value = true;
      bound.value = next;
    }

    void cleared() {
      edited.value = true;
      bound.value = null;
    }

    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Text("Harvest festival start"),
            if (showsMixed)
              DateTimePickerField.mixed(
                includeDate: showsDate,
                includeTime: includeTime,
                showPicker: showPicker,
                minimum: minimum,
                maximum: maximum,
                enabled: enabled,
                readOnly: readOnly,
                onChanged: changed,
                onCleared: cleared,
              )
            else
              DateTimePickerField(
                value: bound.value,
                includeDate: showsDate,
                includeTime: includeTime,
                showPicker: showPicker,
                minimum: minimum,
                maximum: maximum,
                enabled: enabled,
                readOnly: readOnly,
                onChanged: changed,
                onCleared: cleared,
              ),
            Text(switch ((showsMixed, bound.value)) {
              (true, _) => "Bound start: mixed",
              (_, null) => "Bound start: empty",
              (_, final value?) => "Bound start: ${value.toIso8601String()}",
            }),
          ],
        ),
      ),
    );
  }
}
