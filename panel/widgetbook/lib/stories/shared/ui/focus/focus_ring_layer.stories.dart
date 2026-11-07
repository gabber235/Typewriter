import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
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
