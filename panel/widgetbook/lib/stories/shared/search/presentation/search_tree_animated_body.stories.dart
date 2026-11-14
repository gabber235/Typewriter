import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The rows of one result group. The filter buttons narrow them: rows the
/// query drops squash shut and rows it brings back slide in, or jump with
/// reduced motion.
@widgetbook.UseCase(name: "Default", type: SearchTreeAnimatedBody)
Widget searchTreeAnimatedBodyUseCase(BuildContext context) {
  final results = context.knobs.object.segmented(
    label: "Results",
    options: const ["Few", "Many", "Long names", "Empty"],
    initialOption: "Few",
  );
  final width = context.knobs.width(const {"Wide": 640, "Narrow": 300});
  final reduced = context.knobs.boolean(label: "Reduced motion");
  return Story(
    [if (reduced) reducedMotion],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 560,
        child: StorySearchRoot(
          snapshot: storySearchSnapshots[results]!,
          child: const _NarrowingRows(),
        ),
      ),
    ),
  );
}

/// Filter buttons above the rows of the search's tree, flattened into one
/// group; each button searches for its query.
class _NarrowingRows extends HookConsumerWidget {
  const _NarrowingRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final rows = buildSearchTreeViewModel(
      nodes: controller.snapshot.nodes,
      isCollapsed: controller.isCollapsed,
    ).groups.expand((group) => group.rows).toList();
    return Column(
      spacing: context.spacing.space2,
      children: [
        Wrap(
          spacing: context.spacing.space2,
          children: [
            for (final (label, query) in const [
              ("All", ""),
              ("Arrival", "arrival"),
              ("Market", "market"),
              ("Nothing", "nothing matches"),
            ])
              Button(
                label: label,
                face: controller.query == query
                    ? ButtonFace.outlined
                    : ButtonFace.quiet,
                onPressed: () => controller.updateQuery(query),
              ),
          ],
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SearchTreeAnimatedBody(
                rows: rows,
                rowRenderers: storySearchRowRenderers,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
