import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The scope that gives one search its controller. An owned root creates
/// the controller and disposes it with the scope; a borrowed root shows a
/// controller its caller keeps, so the query survives the root.
@widgetbook.UseCase(name: "Default", type: SearchRoot)
Widget searchRootUseCase(BuildContext context) {
  final owner = context.knobs.object.segmented(
    label: "Controller",
    options: const ["Owned", "Borrowed"],
    initialOption: "Owned",
  );
  final results = context.knobs.object.segmented(
    label: "Results",
    options: const ["Few", "Loading", "Error"],
    initialOption: "Few",
  );
  final snapshot = storySearchSnapshots[results]!;
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 640,
        height: 480,
        child: owner == "Borrowed"
            ? _BorrowedRoot(snapshot: snapshot)
            : SearchRoot(
                create: (ref) => _controller(snapshot),
                child: const _Body(),
              ),
      ),
    ),
  );
}

SearchController<void> _controller(SearchSourceSnapshot snapshot) {
  return SearchController<void>(
    session: SearchSession(
      source: StorySearchSource(snapshot),
      interaction: SearchInteraction(
        activation: SearchActivation.command(
          resolve: (_) => storyOpenCommandId,
          dependencies: const [],
        ),
        selectionMode: SearchSelectionMode.single,
        commands: storySearchCommands,
      ),
    ),
    baseSelectors: const [],
  );
}

/// A root borrowing a controller this widget creates and disposes.
class _BorrowedRoot extends HookWidget {
  const _BorrowedRoot({required this.snapshot});

  final SearchSourceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() => _controller(snapshot), [snapshot]);
    useEffect(() => controller.dispose, [controller]);
    return SearchRoot.borrowed(controller: controller, child: const _Body());
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return SearchBody(
      searchHint: "Search pages",
      rowRenderers: storySearchRowRenderers,
    );
  }
}
