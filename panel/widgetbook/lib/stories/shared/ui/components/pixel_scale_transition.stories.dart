import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [PixelScaleTransition] growing a small chip and a wide card by the same
/// number of pixels on their longest side, so both grow alike whatever their
/// size. Drag Pixels to scale them.
@widgetbook.UseCase(name: "Default", type: PixelScaleTransition)
Widget pixelScaleTransitionUseCase(BuildContext context) {
  final pixels = context.knobs.double.slider(
    label: "Pixels",
    initialValue: 8,
    min: -16,
    max: 24,
  );
  final scale = AlwaysStoppedAnimation(pixels);
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          Widget box(double width, String label) => DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceEmphasized,
              borderRadius: context.shapes.mediumBorderRadius,
            ),
            child: SizedBox(
              width: width,
              height: 40,
              child: Center(child: Text(label)),
            ),
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 48,
            children: [
              PixelScaleTransition(pixelScale: scale, child: box(64, "Chip")),
              PixelScaleTransition(pixelScale: scale, child: box(240, "Card")),
            ],
          );
        },
      ),
    ),
  );
}
