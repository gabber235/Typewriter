import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/support/story.dart";

/// How long a new join code stays active: typed as text, or picked from the
/// presets beside the field (above it on a phone), also by 1 to 4 while the
/// field has focus. Less than an hour is refused under the field.
@widgetbook.UseCase(name: "Default", type: DurationInput)
Widget durationInputUseCase(BuildContext context) {
  final initial = context.knobs.object.segmented(
    label: "Duration",
    options: const ["Preset", "Custom", "Too short"],
    initialOption: "Preset",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 520,
    min: 280,
    max: 760,
  );
  return Story(
    context.knobs.windows(),
    at: PanelLocation.component(
      StoryBox(
        width: width,
        child: _Duration(
          initial: switch (initial) {
            "Custom" => const Duration(days: 3, hours: 12),
            "Too short" => const Duration(minutes: 20),
            _ => const Duration(days: 7),
          },
        ),
      ),
    ),
  );
}

/// Keeps the duration, as the join code settings do.
class _Duration extends HookWidget {
  const _Duration({required this.initial});

  final Duration initial;

  @override
  Widget build(BuildContext context) {
    final duration = useState(initial);
    return DurationInput(
      duration: duration.value,
      onDurationChanged: (value) => duration.value = value,
    );
  }
}
