import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [LoadingIndicator] rippling its message, centred in its region or, with
/// Shrink, as small as its text at the top left of the region.
@widgetbook.UseCase(name: "Default", type: LoadingIndicator)
Widget loadingIndicatorUseCase(BuildContext context) {
  final shrink = context.knobs.boolean(label: "Shrink");
  final message = context.knobs.object.segmented(
    label: "Message",
    options: const ["Loading members", "Waiting for the realm to answer"],
    initialOption: "Loading members",
  );
  final width = context.knobs.width(const {"Wide": 480, "Narrow": 240});
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) => SizedBox(
          width: width,
          height: 200,
          child: ColoredBox(
            color: context.colors.surfaceContainer,
            child: Align(
              alignment: Alignment.topLeft,
              child: LoadingIndicator(message: message, shrink: shrink),
            ),
          ),
        ),
      ),
    ),
  );
}
