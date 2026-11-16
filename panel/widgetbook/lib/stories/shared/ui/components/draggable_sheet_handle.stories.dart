import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The grip at the top of a sheet, as a [DraggableSheetHandle] on a sheet
/// card; it only shows that the sheet can be dragged.
@widgetbook.UseCase(name: "Default", type: DraggableSheetHandle)
Widget draggableSheetHandleUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Grip width",
    initialValue: 32,
    min: 16,
    max: 96,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: context.shapes.largeBorderRadius,
          ),
          child: SizedBox(
            width: 320,
            height: 160,
            child: Column(
              children: [
                const SizedBox(height: 12),
                DraggableSheetHandle(width: width),
                const SizedBox(height: 24),
                const Text("Choose a realm"),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
