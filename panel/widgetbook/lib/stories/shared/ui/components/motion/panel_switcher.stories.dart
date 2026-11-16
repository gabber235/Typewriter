import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [PanelSwitcher] swapping popover content: the new panel grows from
/// Origin while the old one goes back with `panelOut`; Closed removes it.
@widgetbook.UseCase(name: "Default", type: PanelSwitcher)
Widget panelSwitcherUseCase(BuildContext context) {
  final panel = context.knobs.object.segmented(
    label: "Panel",
    options: const ["Roles", "Members", "Closed"],
    initialOption: "Roles",
  );
  final origin = context.knobs.object.segmented(
    label: "Origin",
    options: const ["Top left", "Centre"],
    initialOption: "Top left",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          Widget card(String title, List<String> rows) => DecoratedBox(
            key: ValueKey(title),
            decoration: BoxDecoration(
              color: context.colors.surfaceRaised,
              borderRadius: context.shapes.mediumBorderRadius,
            ),
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in rows)
                    PanelRow(dense: true, title: Text(row)),
                ],
              ),
            ),
          );
          return SizedBox(
            width: 280,
            height: 220,
            child: Align(
              alignment: Alignment.topLeft,
              child: PanelSwitcher(
                alignment: origin == "Centre"
                    ? Alignment.center
                    : Alignment.topLeft,
                child: switch (panel) {
                  "Roles" => card("Roles", const ["Owner", "Editor"]),
                  "Members" => card("Members", const ["Ada", "Grace", "Linus"]),
                  _ => null,
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}
