import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _engines = ["Paper", "Fabric", "Minestom", "Velocity", "Folia", "Sponge"];

/// An [AdaptiveChoiceControl] over none, one, a few or many choices, in a
/// field as wide or narrow as the Width knob says. With a preferred default
/// it starts on that choice, or on the sole choice when only one exists.
@widgetbook.UseCase(name: "Default", type: AdaptiveChoiceControl)
Widget adaptiveChoiceControlUseCase(BuildContext context) {
  final count = context.knobs.object.segmented(
    label: "Choices",
    options: const [0, 1, 3, 6],
    initialOption: 3,
  );
  final narrow = context.knobs.boolean(label: "Narrow", initialValue: false);
  final preferred = context.knobs.boolean(
    label: "Preferred default",
    initialValue: false,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: narrow ? 240 : 480,
        child: HookBuilder(
          builder: (context) {
            final selected = useState<String?>(null);
            return AdaptiveChoiceControl<String>(
              choices: {
                for (final engine in _engines.take(count)) engine: engine,
              },
              selected: selected.value,
              defaultValue: preferred ? _engines[count ~/ 2] : null,
              onSelected: (value) => selected.value = value,
            );
          },
        ),
      ),
    ),
  );
}

/// A [SlidingChoiceControl] with one choice disabled, as the icon source
/// picker shows it when SVG icons are not allowed.
@widgetbook.UseCase(name: "Default", type: SlidingChoiceControl)
Widget slidingChoiceControlUseCase(BuildContext context) {
  final disabled = context.knobs.boolean(label: "SVG disabled");
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 360,
        child: HookBuilder(
          builder: (context) {
            final selected = useState("Iconify");
            return SlidingChoiceControl<String>(
              selected: selected.value,
              disabled: disabled ? const {"SVG"} : const {},
              children: const {"Iconify": Text("Iconify"), "SVG": Text("SVG")},
              onSelected: (value) {
                if (value != null) selected.value = value;
              },
            );
          },
        ),
      ),
    ),
  );
}
