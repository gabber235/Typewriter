import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The panel's Rive animations as a [RiveAsset] shows them: the loading
/// tour and the error robot. They play in the browser; a story test renders
/// an empty box, since tests run without the Rive runtime.
@widgetbook.UseCase(name: "Default", type: RiveAsset)
Widget riveAssetUseCase(BuildContext context) {
  final asset = context.knobs.object.segmented(
    label: "Asset",
    options: const ["Loading tour", "Error robot"],
    initialOption: "Loading tour",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox.square(
        dimension: 320,
        child: switch (asset) {
          "Error robot" => const RiveAsset(
            asset: "assets/robot_island.riv",
            stateMachineName: "Motion",
          ),
          _ => const RiveAsset(
            asset: "assets/tour.riv",
            stateMachineName: "state_machine",
          ),
        },
      ),
    ),
  );
}
