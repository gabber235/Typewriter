import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [Section] card around a titled group of rows, on the page surface or
/// in a colour of its own; the rows take the text colour the card's fill
/// needs.
@widgetbook.UseCase(name: "Default", type: Section)
Widget sectionUseCase(BuildContext context) {
  final fill = context.knobs.object.segmented(
    label: "Fill",
    options: const ["Surface", "Brand", "Danger"],
    initialOption: "Surface",
  );
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 240});
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) => SizedBox(
          width: width,
          child: Section(
            backgroundColor: switch (fill) {
              "Brand" => context.colors.brand,
              "Danger" => context.colors.danger,
              _ => null,
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: "Danger zone"),
                PanelRow(
                  title: Text("Delete organization"),
                  subtitle: Text("Removes every realm and member for good"),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
