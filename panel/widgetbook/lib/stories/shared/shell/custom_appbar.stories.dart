import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/shell.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The [SidebarMenuButton] a compact app bar shows in place of the sidebar;
/// pressing it opens the sidebar content as a bottom sheet.
@widgetbook.UseCase(name: "Default", type: SidebarMenuButton)
Widget sidebarMenuButtonUseCase(BuildContext context) {
  return Story(
    [
      signedIn(ada, organization: acme),
      ...context.knobs.traits("Window", {
        "Phone": [window(const Size(360, 720))],
        "Compact": const [compact],
      }),
    ],
    at: const PanelLocation.component(
      SidebarMenuButton(sidebar: StorySidebarContent()),
    ),
  );
}

/// [AppBarBreadcrumbs] from one organization down to a page, joined by
/// chevrons; a path longer than its room scrolls sideways.
@widgetbook.UseCase(name: "Default", type: AppBarBreadcrumbs)
Widget appBarBreadcrumbsUseCase(BuildContext context) {
  final crumbs = context.knobs.object.segmented(
    label: "Breadcrumbs",
    options: const [1, 2, 3, 5],
    initialOption: 3,
  );
  final width = context.knobs.object.segmented(
    label: "Width",
    options: const ["Wide", "Phone"],
    initialOption: "Wide",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: storyBarWidths[width],
        height: 48,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppBarBreadcrumbs(children: storyBreadcrumbs(crumbs)),
        ),
      ),
    ),
  );
}
