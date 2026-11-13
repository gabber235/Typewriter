import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/shell.dart";
import "package:widgetbook_workspace/support/story.dart";

/// [CustomAppBarLayout] fitting breadcrumbs, the search control and one
/// action of every sizing policy into a bar of the chosen width. Narrower
/// bars shorten the search first, then the adaptive action, then swap the
/// wide only action for the compact only one; a bar too narrow for its
/// controls scrolls.
@widgetbook.UseCase(name: "Default", type: CustomAppBarLayout)
Widget customAppBarLayoutUseCase(BuildContext context) {
  final width = context.knobs.object.dropdown(
    label: "Width",
    options: storyBarWidths.keys.toList(),
    initialOption: "Wide",
  );
  final crumbs = context.knobs.object.segmented(
    label: "Breadcrumbs",
    options: const [1, 3, 5],
    initialOption: 3,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: storyBarWidths[width],
        height: 48,
        child: CustomAppBarLayout(
          spacing: 8,
          navigation: AppBarBreadcrumbs(children: storyBreadcrumbs(crumbs)),
          primary: storyPrimaryItem(),
          actions: storyPolicyItems(),
        ),
      ),
    ),
  );
}
