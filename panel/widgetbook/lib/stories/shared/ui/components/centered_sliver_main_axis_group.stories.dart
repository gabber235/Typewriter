import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// Rows in a [CenteredSliverMainAxisGroup]: a few rows sit in the middle of
/// the viewport, and once they no longer fit they scroll from the top as
/// usual. Drag Rows to cross that point.
@widgetbook.UseCase(name: "Default", type: CenteredSliverMainAxisGroup)
Widget centeredSliverMainAxisGroupUseCase(BuildContext context) {
  final rows = context.knobs.int.slider(
    label: "Rows",
    initialValue: 3,
    min: 0,
    max: 20,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => SizedBox(
          width: 360,
          height: 400,
          child: ColoredBox(
            color: context.colors.surfaceContainer,
            child: CustomScrollView(
              slivers: [
                CenteredSliverMainAxisGroup(
                  slivers: [
                    SliverList.list(
                      children: [
                        for (var row = 1; row <= rows; row++)
                          PanelRow(title: Text("Realm $row")),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
