import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The saved colors of the color popup: a press picks one, and when the
/// caller allows it a swatch can be removed or moved. With no swatches the
/// grid takes no room.
@widgetbook.UseCase(name: "Saved colors", type: ColorSwatchGrid)
Widget colorSwatchGridUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    ColorSwatchGridStory(
      count: context.knobs.object.segmented(
        label: "Swatches",
        options: const [0, 3, 24],
        initialOption: 3,
        labelBuilder: (count) => switch (count) {
          0 => "Empty",
          3 => "Few",
          _ => "Many",
        },
      ),
      editable: context.knobs.boolean(
        label: "Removable and movable",
        initialValue: true,
      ),
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.width(const {"Popup": 288, "Narrow": 120}),
    ),
  ),
);

/// Keeps the swatches a [ColorSwatchGrid] edits and the color last picked.
class ColorSwatchGridStory extends HookWidget {
  const ColorSwatchGridStory({
    required this.count,
    required this.editable,
    required this.enabled,
    required this.width,
    super.key,
  });

  final int count;
  final bool editable;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = useState([
      for (var index = 0; index < count; index++)
        HSVColor.fromAHSV(
          1,
          index * 360 / (count + 1),
          0.7,
          0.9,
        ).toColor().argbValue,
    ]);
    final picked = useState<int?>(null);
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text("Saved colors"),
          ColorSwatchGrid(
            label: "Saved colors",
            colors: colors.value,
            enabled: enabled,
            onSelected: (argb) => picked.value = argb,
            onRemoved: editable
                ? (argb) => colors.value = [
                    for (final color in colors.value)
                      if (color != argb) color,
                  ]
                : null,
            onReordered: editable ? (next) => colors.value = next : null,
          ),
          Text(switch (picked.value) {
            null => "Nothing picked",
            final argb =>
              "Picked #${argb.toRadixString(16).toUpperCase().padLeft(8, "0")}",
          }),
        ],
      ),
    );
  }
}
