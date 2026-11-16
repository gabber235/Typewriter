import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The Width knob of a result list.
double _width(BuildContext context) {
  return context.knobs.width(const {"Wide": 640, "Narrow": 300});
}

/// A search over [snapshot] in a box [width] wide, with the shell's
/// motion or the reduced one.
Widget _searchStory({
  required SearchSourceSnapshot snapshot,
  required double width,
  required Widget child,
  SearchCommandExecutionState commandState =
      const SearchCommandExecutionState.idle(),
  bool reduced = false,
  double height = 560,
}) {
  return Story(
    [if (reduced) reducedMotion],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: height,
        child: StorySearchRoot(
          snapshot: snapshot,
          commandState: commandState,
          child: child,
        ),
      ),
    ),
  );
}

/// The result tree of a search: source failures and guidance above the
/// results, Books as folding sections, and the empty, loading and failure
/// states when no row shows. Clicking a section header folds it; clicking
/// a result opens it.
@widgetbook.UseCase(name: "Default", type: SearchTreeResults)
Widget searchTreeResultsUseCase(BuildContext context) {
  final snapshot = context.knobs.searchResults();
  final commandState = context.knobs.searchCommand();
  final ownEmpty = context.knobs.boolean(label: "Own empty and loading");
  final reduced = context.knobs.boolean(label: "Reduced motion");
  return _searchStory(
    snapshot: snapshot,
    commandState: commandState,
    width: _width(context),
    reduced: reduced,
    child: SearchTreeResults(
      rowRenderers: storySearchRowRenderers,
      empty: ownEmpty
          ? const EmptyScreen(title: "No pages match", small: true)
          : null,
      loading: ownEmpty
          ? const Center(child: MotionLabel("Searching pages", rippling: true))
          : null,
    ),
  );
}

/// A failure a search source reports above its results. It shrinks to its
/// source as the results scroll under it.
@widgetbook.UseCase(name: "Default", type: SearchErrorSummarySliver)
Widget searchErrorSummarySliverUseCase(BuildContext context) {
  final severity = context.knobs.object.segmented(
    label: "Severity",
    options: SearchErrorSeverity.values,
    initialOption: SearchErrorSeverity.error,
    labelBuilder: (severity) => severity.name,
  );
  final long = context.knobs.boolean(label: "Long message");
  final source = context.knobs.boolean(label: "Source", initialValue: true);
  return _sliverStory(
    width: _width(context),
    sliver: SearchErrorSummarySliver(
      error: SearchErrorSummary(
        id: "story.error",
        message: long
            ? "The realm did not answer within ten seconds while it was "
                  "reading the pages of every Book, so the results below may "
                  "be missing pages saved in the last minute. Search again "
                  "to retry."
            : "The realm did not answer. Search again to retry.",
        severity: severity,
        sourceLabel: source ? "Realm" : null,
      ),
    ),
  );
}

/// Guidance a search source offers above its results, such as how to
/// narrow a search.
@widgetbook.UseCase(name: "Default", type: SearchGuidanceSliver)
Widget searchGuidanceSliverUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long description");
  final description = context.knobs.boolean(
    label: "Description",
    initialValue: true,
  );
  return _sliverStory(
    width: _width(context),
    sliver: SearchGuidanceSliver(
      guidance: SearchGuidance(
        id: "story.guidance",
        title: "Narrow by book",
        description: !description
            ? null
            : long
            ? "Type book: and the name of a Book to search only its pages, "
                  "or chapter: and a chapter path to search one chapter of "
                  "every Book in the realm."
            : "Type book: and a book name to search one book.",
      ),
    ),
  );
}

/// [sliver] above a few plain rows, in a scroll view [width] wide.
Widget _sliverStory({required double width, required Widget sliver}) {
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 360,
        child: CustomScrollView(
          slivers: [
            sliver,
            SliverList.list(
              children: [
                for (final page in ["Arrival", "Market", "Finale"])
                  PanelRow(dense: true, title: Text(page)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// One row of a result tree: a section header, a result drawn by its
/// renderer, or a result whose kind has no renderer. A command running on
/// the result presses it in; a failed one jams it.
@widgetbook.UseCase(name: "Default", type: SearchTreeRowWidget)
Widget searchTreeRowWidgetUseCase(BuildContext context) {
  final kind = context.knobs.object.segmented(
    label: "Row",
    options: const ["Section", "Result", "Nested result", "No renderer"],
    initialOption: "Result",
  );
  final command = context.knobs.object.segmented(
    label: "Command",
    options: storyCommandStates.keys.toList(),
    initialOption: "Idle",
  );
  final result = SearchResult(
    id: storyFirstResultId,
    type: kind == "No renderer"
        ? const SearchResultType(
            id: "story.unknown",
            rowRendererId: "story.unknown",
            label: "Unknown",
          )
        : storyResultType,
    payload: storyFirstResultId,
    title: "Arrival",
    subtitle: "The Lost Village",
  );
  final row = switch (kind) {
    "Section" => SearchTreeRow.section(
      key: searchTreeSectionKey("village"),
      depth: 0,
      id: "village",
      title: "The Lost Village",
      subtitle: "Book",
      expanded: true,
      resultCount: 3,
      topLevel: true,
    ),
    _ => SearchTreeRow.result(
      key: searchTreeResultKey(storyFirstResultId),
      depth: kind == "Nested result" ? 2 : 0,
      result: result,
      shortcutNumber: 1,
    ),
  };
  return _searchStory(
    snapshot: SearchSourceSnapshot.ready(
      nodes: [SearchNode.result(result: result)],
    ),
    commandState: storyCommandStates[command]!,
    width: _width(context),
    height: 120,
    child: SearchTreeRowWidget(row: row, rowRenderers: storySearchRowRenderers),
  );
}

/// One top level group of a result tree: a Book's pinned header above its
/// rows, which stays while the rows scroll. Clicking the header folds it.
@widgetbook.UseCase(name: "Default", type: SearchTreeSectionSliver)
Widget searchTreeSectionSliverUseCase(BuildContext context) {
  final snapshot = context.knobs.searchResults(
    options: const ["Sections", "Nested sections", "Many", "Long names"],
  );
  final reduced = context.knobs.boolean(label: "Reduced motion");
  return _searchStory(
    snapshot: snapshot,
    width: _width(context),
    reduced: reduced,
    child: const _SectionSlivers(),
  );
}

/// The section slivers of the search's current tree, folding as the
/// search's controller says.
class _SectionSlivers extends ConsumerWidget {
  const _SectionSlivers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final groups = buildSearchTreeViewModel(
      nodes: controller.snapshot.nodes,
      isCollapsed: controller.isCollapsed,
    ).groups;
    return CustomScrollView(
      slivers: [
        for (final (index, group) in groups.indexed)
          SearchTreeSectionSliver(
            key: ValueKey(group.section?.key ?? "group:$index"),
            group: group,
            rowRenderers: storySearchRowRenderers,
          ),
      ],
    );
  }
}
