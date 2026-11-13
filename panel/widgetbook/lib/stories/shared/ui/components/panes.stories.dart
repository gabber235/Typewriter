import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Three [Pane]s side by side: the primary middle pane opens on its first
/// row, Tab stays inside a pane, and Ctrl with an arrow or H, J, K, L moves
/// to the pane in that direction. Without Sidebar enabled the left pane is
/// skipped.
@widgetbook.UseCase(name: "Three panes", type: Pane)
Widget paneUseCase(BuildContext context) {
  final sidebar = context.knobs.boolean(
    label: "Sidebar enabled",
    initialValue: true,
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(PanesStory(sidebarEnabled: sidebar)),
  );
}

/// The [GlobalPaneNavigator] the shell installs, moving focus between the
/// panes of [PanesStory] by their bounds: Ctrl with an arrow or H, J, K, L.
@widgetbook.UseCase(name: "Moving between panes", type: GlobalPaneNavigator)
Widget globalPaneNavigatorUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: const PanelLocation.component(PanesStory()),
  );
}

/// A sidebar, a primary list and an inspector, each a [Pane] of rows.
class PanesStory extends StatelessWidget {
  const PanesStory({this.sidebarEnabled = true, super.key});

  final bool sidebarEnabled;

  @override
  Widget build(BuildContext context) {
    Widget pane(
      String id,
      List<String> rows, {
      bool primary = false,
      bool enabled = true,
    }) => Expanded(
      child: Pane(
        id: id,
        primary: primary,
        enabled: enabled,
        openFocus: primary ? PaneOpenFocus.firstItem : PaneOpenFocus.none,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            borderRadius: context.shapes.mediumBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(title: id),
              for (final row in rows)
                PanelRow(dense: true, title: Text(row), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    return SizedBox(
      width: 720,
      height: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pane("Sidebar", const ["Pages", "Members"], enabled: sidebarEnabled),
          pane("Pages", const ["Intro", "Harbour", "Finale"], primary: true),
          pane("Inspector", const ["Name", "Speaker"]),
        ],
      ),
    );
  }
}
