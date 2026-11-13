import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The checker pattern under a translucent color, so its alpha reads: a
/// fully opaque fill hides it, a clear one shows only the checks.
@widgetbook.UseCase(name: "Under a translucent color", type: Checkerboard)
Widget checkerboardUseCase(BuildContext context) {
  final alpha = context.knobs.object.segmented(
    label: "Alpha",
    options: const ["Clear", "Half", "Opaque"],
    initialOption: "Half",
  );
  final rounded = context.knobs.boolean(label: "Rounded", initialValue: true);
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          return Checkerboard(
            borderRadius: rounded
                ? context.shapes.mediumBorderRadius
                : BorderRadius.zero,
            child: SizedBox(
              width: 160,
              height: 96,
              child: ColoredBox(
                color: const Color(0xFF7C4DFF).withValues(
                  alpha: switch (alpha) {
                    "Clear" => 0,
                    "Opaque" => 1,
                    _ => 0.5,
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
