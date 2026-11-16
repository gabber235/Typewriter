import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// An [AnimatedStatusContent] as an app bar status: pick another Status to
/// watch the icon and label switch in place; Compact drops the label at
/// once. The last status has no label.
@widgetbook.UseCase(name: "Default", type: AnimatedStatusContent)
Widget animatedStatusContentUseCase(BuildContext context) {
  final status = context.knobs.object.segmented(
    label: "Status",
    options: const ["Saved", "Saving", "Offline", "Icon only"],
    initialOption: "Saved",
  );
  final compact = context.knobs.boolean(label: "Compact");
  final (icon, label) = switch (status) {
    "Saving" => (Icons.sync, "Saving changes"),
    "Offline" => (Icons.cloud_off_outlined, "Offline, changes wait"),
    "Icon only" => (Icons.check_circle_outline, null),
    _ => (Icons.cloud_done_outlined, "Saved"),
  };
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      AnimatedStatusContent(
        icon: Icon(icon, key: ValueKey(icon)),
        label: label,
        compact: compact,
      ),
    ),
  );
}
