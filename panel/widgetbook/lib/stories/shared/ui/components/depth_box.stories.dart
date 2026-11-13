import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// [DepthBox]es nested Depth deep: each level alternates its surface so the
/// nesting reads without borders. Without Enabled the boxes draw nothing.
@widgetbook.UseCase(name: "Nested", type: DepthBox)
Widget depthBoxUseCase(BuildContext context) {
  final depth = context.knobs.int.slider(
    label: "Depth",
    initialValue: 3,
    min: 1,
    max: 5,
  );
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  Widget nested(int level) {
    if (level > depth) return const SizedBox.shrink();
    return DepthBox(
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [Text("Level $level"), nested(level + 1)],
        ),
      ),
    );
  }

  return Story(
    const [],
    at: PanelLocation.component(SizedBox(width: 360, child: nested(1))),
  );
}
