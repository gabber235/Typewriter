import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/design_system/focus_ring_demo.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The one focus ring: Tab moves it across two panes of rows, a button, a
/// field and a table row, and the arrow keys in the search field move it
/// over the results while the field keeps focus.
@widgetbook.UseCase(name: "Default", type: FocusRingLayer)
Widget focusRingLayerUseCase(BuildContext context) {
  return const Story([], at: PanelLocation.component(FocusRingDemo()));
}

/// A result list whose highlighted row is a [RingCursor]: pick Cursor to
/// move the ring over the rows while focus stays elsewhere; without Active
/// the ring goes back to real focus.
@widgetbook.UseCase(name: "Result cursor", type: RingCursor)
Widget ringCursorUseCase(BuildContext context) {
  final cursor = context.knobs.object.segmented(
    label: "Cursor",
    options: const ["Ada", "Grace", "Linus"],
    initialOption: "Ada",
  );
  final active = context.knobs.boolean(label: "Active", initialValue: true);
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) => SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in const ["Ada", "Grace", "Linus"])
                RingCursor(
                  active: active && name == cursor,
                  borderRadius: context.shapes.mediumBorderRadius,
                  child: PanelRow(dense: true, title: Text(name)),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
