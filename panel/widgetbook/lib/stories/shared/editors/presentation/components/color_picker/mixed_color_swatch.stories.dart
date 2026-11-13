import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The swatch a color field shows when the selected resources hold
/// different colors.
@widgetbook.UseCase(name: "Sizes", type: MixedColorSwatch)
Widget mixedColorSwatchUseCase(BuildContext context) {
  final size = context.knobs.object.segmented(
    label: "Size",
    options: const [16.0, 24.0, 48.0],
    initialOption: 24.0,
    labelBuilder: (size) => "${size.round()}",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          MixedColorSwatch(size: size),
          const Text("Mixed"),
        ],
      ),
    ),
  );
}
