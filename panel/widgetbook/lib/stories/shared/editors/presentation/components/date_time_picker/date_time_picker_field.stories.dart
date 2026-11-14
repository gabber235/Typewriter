import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Text and picker editing", type: DateTimePickerField)
Widget dateTimePickerFieldUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    DateTimePickerFieldStory(
      includeDate: context.knobs.boolean(
        label: "Include date",
        initialValue: true,
      ),
      includeTime: context.knobs.boolean(
        label: "Include time",
        initialValue: true,
      ),
      showPicker: context.knobs.boolean(
        label: "Show picker action",
        initialValue: true,
      ),
      bounded: context.knobs.boolean(
        label: "Limit to the event window",
        initialValue: false,
      ),
      mixed: context.knobs.boolean(label: "Mixed selection"),
      field: context.knobs.field(),
    ),
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
    this.field = const FieldKnobs(),
    super.key,
  });

  final bool includeDate;
  final bool includeTime;
  final bool showPicker;
  final bool bounded;
  final bool mixed;
  final FieldKnobs field;

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

    return SizedBox(
      width: field.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const Text("Harvest festival start"),
          // A mixed selection shows no value until the user edits it; the
          // display knobs shape the field once it holds a value.
          if (showsMixed)
            DateTimePickerField(
              value: null,
              mixed: true,
              includeDate: showsDate,
              includeTime: includeTime,
              enabled: field.enabled,
              readOnly: field.readOnly,
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
              enabled: field.enabled,
              readOnly: field.readOnly,
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
    );
  }
}

@widgetbook.UseCase(name: "Surface", type: DateTimePickerSurface)
Widget dateTimePickerSurfaceUseCase(BuildContext context) {
  final mode = context.knobs.object.dropdown(
    label: "Parts",
    options: const ["Date and time", "Date", "Time"],
    initialOption: "Date and time",
  );
  final bounded = context.knobs.boolean(label: "Limit to the event window");
  return Story(
    const [],
    at: PanelLocation.component(
      DateTimePickerSurfaceStory(
        includeDate: mode != "Time",
        includeTime: mode != "Date",
        minimum: bounded ? DateTime.utc(2026, 10, 24) : null,
        maximum: bounded ? DateTime.utc(2026, 11, 7, 23, 59, 59) : null,
      ),
    ),
  );
}

/// The open date and time popup of a seasonal event start, keeping the
/// moment it picks.
class DateTimePickerSurfaceStory extends HookWidget {
  const DateTimePickerSurfaceStory({
    required this.includeDate,
    required this.includeTime,
    this.minimum,
    this.maximum,
    super.key,
  });

  final bool includeDate;
  final bool includeTime;
  final DateTime? minimum;
  final DateTime? maximum;

  @override
  Widget build(BuildContext context) {
    final value = useState(DateTime.utc(2026, 10, 31, 18, 30));
    return SizedBox(
      width: 360,
      child: DateTimePickerSurface(
        value: value.value,
        includeDate: includeDate,
        includeTime: includeTime,
        enabled: true,
        minimum: minimum,
        maximum: maximum,
        onChanged: (next) => value.value = next,
      ),
    );
  }
}
