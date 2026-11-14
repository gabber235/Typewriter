import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Three [RingTarget]s with their own corner radius: press Tab to bring the
/// ring in and watch it travel between them with `focusMove`, taking each
/// target's shape. A click focuses without a ring.
@widgetbook.UseCase(name: "Default", type: RingTarget)
Widget ringTargetUseCase(BuildContext context) {
  final rounded = context.knobs.boolean(label: "Rounded", initialValue: true);
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          final radius = rounded
              ? context.shapes.mediumBorderRadius
              : BorderRadius.zero;
          Widget target(String label, double width) => RingTarget(
            borderRadius: radius,
            child: Focus(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: radius,
                ),
                child: SizedBox(
                  width: width,
                  height: 48,
                  child: Center(child: Text(label)),
                ),
              ),
            ),
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              target("Small", 80),
              target("Wide target", 200),
              target("Medium", 120),
            ],
          );
        },
      ),
    ),
  );
}
