import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [SurfaceContainer] whose fill moves with `ink` when Fill changes; the
/// text keeps its contrast on every fill, and None shows the parent surface.
/// Padding grows the card with the same move.
@widgetbook.UseCase(name: "Default", type: SurfaceContainer)
Widget surfaceContainerUseCase(BuildContext context) {
  final fill = context.knobs.object.segmented(
    label: "Fill",
    options: const ["None", "Soft", "Brand", "Danger"],
    initialOption: "Soft",
  );
  final roomy = context.knobs.boolean(label: "Roomy padding");
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          final color = switch (fill) {
            "Soft" => context.colors.surfaceEmphasized,
            "Brand" => context.colors.brand,
            "Danger" => context.colors.danger,
            _ => null,
          };
          return SurfaceContainer(
            motion: resolveMotion(context, MotionToken.ink),
            decoration: BoxDecoration(
              color: color,
              borderRadius: context.shapes.mediumBorderRadius,
            ),
            padding: EdgeInsets.all(roomy ? 32 : 12),
            width: 280,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quest board"),
                Text("Three pages, published yesterday"),
              ],
            ),
          );
        },
      ),
    ),
  );
}
