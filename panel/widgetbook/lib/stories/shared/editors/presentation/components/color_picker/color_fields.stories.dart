import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The typed fields of the color popup in each format, with or without an
/// alpha channel; a valid draft changes the color shown below.
@widgetbook.UseCase(name: "Formats", type: ColorFields)
Widget colorFieldsUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    ColorFieldsStory(
      format: context.knobs.object.segmented(
        label: "Format",
        options: ColorFieldFormat.values,
        initialOption: ColorFieldFormat.hex,
        labelBuilder: (format) => format.name.toUpperCase(),
      ),
      includeAlpha: context.knobs.boolean(
        label: "Include alpha",
        initialValue: true,
      ),
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 288, "Narrow": 180}),
    ),
  ),
);

/// Keeps the color and format [ColorFields] edit.
class ColorFieldsStory extends HookWidget {
  const ColorFieldsStory({
    required this.format,
    required this.includeAlpha,
    required this.enabled,
    required this.width,
    super.key,
  });

  final ColorFieldFormat format;
  final bool includeAlpha;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = useState(const Color(0xCC3F51B5));
    final shown = useState(format);
    useEffect(() {
      shown.value = format;
      return null;
    }, [format]);
    final hex = color.value.argbValue
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, "0");
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ColorFields(
            color: color.value,
            format: shown.value,
            includeAlpha: includeAlpha,
            enabled: enabled,
            onFormatChanged: (next) => shown.value = next,
            onChanged: (next) => color.value = next,
          ),
          Row(
            spacing: 8,
            children: [
              Checkerboard(
                child: SizedBox.square(
                  dimension: 24,
                  child: ColoredBox(color: color.value),
                ),
              ),
              Expanded(child: Text("#$hex")),
            ],
          ),
        ],
      ),
    );
  }
}
