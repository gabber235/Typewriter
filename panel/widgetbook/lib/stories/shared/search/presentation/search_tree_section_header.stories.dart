import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The header of a result section, such as a Book grouping its pages, with
/// how many results it holds. Clicking it folds the section and turns its
/// chevron; nested sections indent by their depth.
@widgetbook.UseCase(name: "Default", type: SearchTreeSectionHeader)
Widget searchTreeSectionHeaderUseCase(BuildContext context) {
  final depth = context.knobs.object.segmented(
    label: "Depth",
    options: const [0, 1, 2],
    initialOption: 0,
    labelBuilder: (depth) => "$depth",
  );
  final subtitle = context.knobs.boolean(label: "Subtitle", initialValue: true);
  final long = context.knobs.boolean(label: "Long name");
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 260});
  final reduced = context.knobs.boolean(label: "Reduced motion");
  return Story(
    [if (reduced) reducedMotion],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: _FoldingHeader(
          depth: depth,
          title: long
              ? "The Remarkably Long Chronicle of the Village That Was Lost "
                    "Twice and Found Again"
              : "The Lost Village",
          subtitle: subtitle
              ? long
                    ? "A Book whose name runs past every column of the search"
                    : "Book"
              : null,
        ),
      ),
    ),
  );
}

/// A section header that folds and unfolds when clicked.
class _FoldingHeader extends HookWidget {
  const _FoldingHeader({
    required this.depth,
    required this.title,
    required this.subtitle,
  });

  final int depth;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(true);
    return SearchTreeSectionHeader(
      row: SearchTreeSectionRow(
        key: searchTreeSectionKey("village"),
        depth: depth,
        id: "village",
        title: title,
        subtitle: subtitle,
        expanded: expanded.value,
        resultCount: 12,
        topLevel: depth == 0,
      ),
      onToggle: () => expanded.value = !expanded.value,
    );
  }
}
