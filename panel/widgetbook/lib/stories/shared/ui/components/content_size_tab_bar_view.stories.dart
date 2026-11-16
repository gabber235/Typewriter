import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Tabs over a [ContentSizeTabBarView] whose pages differ in height: pick a
/// tab, or drag the pages sideways, and the view takes the height of the
/// page it shows, so the line below moves with it.
@widgetbook.UseCase(name: "Default", type: ContentSizeTabBarView)
Widget contentSizeTabBarViewUseCase(BuildContext context) {
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      DefaultTabController(
        length: 3,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: "Members"),
                  Tab(text: "Join codes"),
                  Tab(text: "Requests"),
                ],
              ),
              ContentSizeTabBarView(
                children: [
                  _page(const ["Ada", "Grace", "Linus", "Ken"]),
                  _page(const ["Spring"]),
                  _page(const ["Bjarne", "Barbara"]),
                ],
              ),
              const Text("Below the tabs"),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _page(List<String> rows) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [for (final row in rows) PanelRow(dense: true, title: Text(row))],
  );
}
