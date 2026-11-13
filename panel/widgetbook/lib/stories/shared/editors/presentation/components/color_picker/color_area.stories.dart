import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The saturation and value square of the color popup: a press or drag
/// picks the point, the arrow keys nudge it, and the readout shows what it
/// would write.
@widgetbook.UseCase(name: "Pick saturation and value", type: ColorArea)
Widget colorAreaUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    ColorAreaStory(
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 288, "Narrow": 160}),
    ),
  ),
);

/// Keeps the color a [ColorArea] picks and shows it below.
class ColorAreaStory extends HookWidget {
  const ColorAreaStory({required this.enabled, required this.width, super.key});

  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = useState(HSVColor.fromColor(const Color(0xFF3F51B5)));
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SizedBox(
            height: width * 0.75,
            child: ColorArea(
              color: color.value,
              enabled: enabled,
              onChanged: (next) => color.value = next,
            ),
          ),
          Text(
            "Saturation ${(color.value.saturation * 100).round()}%, "
            "value ${(color.value.value * 100).round()}%",
          ),
        ],
      ),
    );
  }
}
