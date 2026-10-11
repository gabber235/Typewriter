import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Progressive fitting", type: CustomAppBar)
Widget customAppBarUseCase(BuildContext context) => AppBarStory(
  width: context.knobs.double.slider(
    label: "Bar width",
    initialValue: 900,
    min: 120,
    max: 1200,
  ),
  joint: context.knobs.boolean(label: "Collapse together"),
  label: context.knobs.string(label: "Activity label", initialValue: "Publish"),
);

@widgetbook.UseCase(name: "Text and filled", type: AppBarControl)
Widget appBarControlUseCase(BuildContext context) => AppBarStory(
  width: context.knobs.double.slider(
    label: "Control space",
    initialValue: 650,
    min: 120,
    max: 1000,
  ),
  label: context.knobs.string(
    label: "Control label",
    initialValue: "Needs attention",
  ),
);

@widgetbook.UseCase(name: "Grouped presence", type: AppBarItem)
Widget appBarItemUseCase(BuildContext context) => AppBarStory(
  width: context.knobs.double.slider(
    label: "Available width",
    initialValue: 360,
    min: 120,
    max: 1000,
  ),
  joint: context.knobs.boolean(label: "Shared collapse group"),
);

@widgetbook.UseCase(name: "Workspace navigation", type: AppBarBreadcrumbs)
Widget appBarBreadcrumbsUseCase(BuildContext context) =>
    const AppBarStory(width: 800);

@widgetbook.UseCase(name: "Route sidebar", type: SidebarMenuButton)
Widget sidebarMenuUseCase(BuildContext context) =>
    const AppBarStory(width: 160);

class AppBarStory extends StatelessWidget {
  const AppBarStory({
    required this.width,
    this.joint = false,
    this.label = "Publish",
    super.key,
  });
  final double width;
  final bool joint;
  final String label;

  @override
  Widget build(BuildContext context) => FakeApp(
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        child: CustomAppBar(
          navigation: AppBarBreadcrumbs(
            children: [
              TextButton(onPressed: () {}, child: const Text("Typewriter")),
              TextButton(
                onPressed: () {},
                child: const Text("Bright Purple Swan"),
              ),
            ],
          ),
          primary: AppBarItem.adaptive(
            key: const ValueKey("search"),
            collapseOrder: 0,
            child: AppBarControl.filled(
              icon: const Icon(Icons.search),
              label: "Search",
              preferredWidth: 360,
              tooltip: "Search",
              semanticLabel: "Search",
              onPressed: () {},
            ),
          ),
          actions: [
            AppBarItem.adaptive(
              key: const ValueKey("activity"),
              collapseOrder: joint ? 0 : 1,
              child: AnchoredPopup(
                targetAnchor: Alignment.bottomRight,
                popupAnchor: Alignment.topRight,
                builder: (context, open) => AppBarControl.text(
                  icon: const Icon(Icons.inbox_outlined),
                  label: label,
                  tooltip: "Realm inbox",
                  semanticLabel: "Realm inbox",
                  onPressed: open,
                ),
                popupBuilder: (context, close) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Realm inbox"),
                      const TextField(
                        autofocus: true,
                        decoration: InputDecoration(labelText: "Filter issues"),
                      ),
                      TextButton(onPressed: close, child: const Text("Close")),
                    ],
                  ),
                ),
              ),
            ),
            AppBarItem.expandedOnly(
              key: const ValueKey("mode"),
              collapseOrder: joint ? 0 : 2,
              child: const Text("NORMAL"),
            ),
            AppBarItem.compactOnly(
              key: const ValueKey("sidebar"),
              collapseOrder: joint ? 0 : 2,
              child: const SidebarMenuButton(sidebar: Text("Realm navigation")),
            ),
          ],
        ),
      ),
    ),
  );
}
