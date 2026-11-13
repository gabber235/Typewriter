import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// One channel of the color popup: hue over the rainbow, or alpha over the
/// checker pattern. A drag or the arrow, Page, Home and End keys move it.
@widgetbook.UseCase(name: "Channels", type: ColorChannelSlider)
Widget colorChannelSliderUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    ColorChannelSliderStory(
      alpha:
          context.knobs.object.segmented(
            label: "Channel",
            options: const ["Hue", "Alpha"],
            initialOption: "Hue",
          ) ==
          "Alpha",
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 288, "Narrow": 140}),
    ),
  ),
);

/// Keeps the value a [ColorChannelSlider] picks and shows it below.
class ColorChannelSliderStory extends HookWidget {
  const ColorChannelSliderStory({
    required this.alpha,
    required this.enabled,
    required this.width,
    super.key,
  });

  final bool alpha;
  final bool enabled;
  final double width;

  static const _hues = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    final value = useState(0.6);
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ColorChannelSlider(
            label: alpha ? "Alpha" : "Hue",
            value: value.value,
            checkerboard: alpha,
            enabled: enabled,
            gradient: LinearGradient(
              colors: alpha
                  ? const [Color(0x007C4DFF), Color(0xFF7C4DFF)]
                  : _hues,
            ),
            onChanged: (next) => value.value = next,
          ),
          Text("${alpha ? "Alpha" : "Hue"} ${(value.value * 100).round()}%"),
        ],
      ),
    );
  }
}
