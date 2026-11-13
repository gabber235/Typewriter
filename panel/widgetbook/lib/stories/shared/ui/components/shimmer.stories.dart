import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A member list loading under one [Shimmer]: avatars, names and a badge
/// sweep as one gradient across separate placeholders. Under reduced motion
/// the placeholders stay still.
@widgetbook.UseCase(name: "Loading list", type: Shimmer)
Widget shimmerUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Shimmer(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              for (var row = 0; row < 3; row++)
                Row(
                  spacing: 12,
                  children: [
                    const ShimmerBox.circle(width: 40, height: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          ShimmerBox.rectangle(width: 160, height: 14),
                          ShimmerBox.rectangle(width: 100, height: 10),
                        ],
                      ),
                    ),
                    const ShimmerBox.stadium(width: 56, height: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// [ShimmerLoading] turning a hand drawn placeholder (a card outline with
/// two bars) into a sweeping one.
@widgetbook.UseCase(name: "Custom placeholder", type: ShimmerLoading)
Widget shimmerLoadingUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Shimmer(
        child: ShimmerLoading(
          child: Container(
            width: 280,
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One [ShimmerBox] in each shape it comes in.
@widgetbook.UseCase(name: "Shapes", type: ShimmerBox)
Widget shimmerBoxUseCase(BuildContext context) {
  final shape = context.knobs.object.segmented(
    label: "Shape",
    options: const ["Rectangle", "Circle", "Stadium"],
    initialOption: "Rectangle",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Shimmer(
        child: switch (shape) {
          "Circle" => const ShimmerBox.circle(width: 64, height: 64),
          "Stadium" => const ShimmerBox.stadium(width: 160, height: 32),
          _ => ShimmerBox.rectangle(width: 200, height: 40),
        },
      ),
    ),
  );
}
