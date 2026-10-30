import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The [LoadingScreen] shown at boot and while the backend connection is
/// (re)established, with its rotating connection messages; with reduced
/// motion the messages stay still.
@widgetbook.UseCase(name: "Default", type: LoadingScreen)
Widget loadingScreenUseCase(BuildContext context) {
  final title = context.knobs.object.segmented(
    label: "Title",
    options: const ["Waiting for connection", "Authenticating User"],
    initialOption: "Waiting for connection",
  );
  final reducedMotion = context.knobs.boolean(label: "Reduce motion");
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: LoadingScreen(title: title),
          );
        },
      ),
    ),
  );
}
