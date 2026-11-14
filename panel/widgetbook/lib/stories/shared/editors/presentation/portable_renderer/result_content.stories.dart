import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A resource as a search result or picker row: its name, accent and icon
/// come from its appearance, and its presentation adds read only details
/// below. A value that is not a resource shows its details alone.
@widgetbook.UseCase(name: "Result rows", type: PortableResultContent)
Widget portableResultContentUseCase(BuildContext context) {
  final card = context.knobs.boolean(label: "Card", initialValue: true);
  final details = context.knobs.boolean(label: "Details", initialValue: true);
  final resource = context.knobs.boolean(label: "Resource", initialValue: true);
  final loading = context.knobs.boolean(label: "Loading");
  final longName = context.knobs.boolean(label: "Long name");
  final width = context.knobs.width(const {"Picker": 360, "Narrow": 220});
  final name = longName
      ? "The mayor's lost lantern in the flooded cellar below the old church"
      : "Find the lantern";
  return Story(
    const [],
    at: PanelLocation.component(
      PortableResultContentStory(
        name: name,
        density: card ? SearchResultDensity.card : SearchResultDensity.compact,
        details: details,
        resource: resource,
        loading: loading,
        width: width,
      ),
    ),
  );
}

/// One [PortableResultContent] row for a quest named [name].
class PortableResultContentStory extends HookWidget {
  const PortableResultContentStory({
    required this.name,
    required this.density,
    required this.details,
    required this.resource,
    required this.loading,
    required this.width,
    super.key,
  });

  final String name;
  final SearchResultDensity density;
  final bool details;
  final bool resource;
  final bool loading;
  final double width;

  @override
  Widget build(BuildContext context) {
    final operations = useMemoized(PortableOperationResults.new);
    useEffect(() => operations.dispose, [operations]);
    final node = details
        ? presentationColumn("details", [
            presentationText(
              "summary",
              textLiteral("Main quest. Starts in the village square"),
            ),
          ])
        : presentationColumn("details", const []);
    return SizedBox(
      width: width,
      child: PortableResultContent(
        node: node,
        scope: PortablePresentationScope(
          bindings: const {},
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          operations: operations,
          role: skir.PresentationRole.resourceSearchResult,
        ),
        row: SearchResultRowContext(
          result: SearchResult(
            id: "quest:lantern",
            type: const SearchResultType(
              id: "quest",
              rowRendererId: "quest.row",
              label: "Quest",
            ),
            payload: "quest:lantern",
            title: name,
          ),
          selected: false,
          focused: true,
          loading: loading,
          onTap: () {},
        ),
        density: density,
        kindLabel: "Quest",
        appearance: resource
            ? skir.ResourceAppearance(
                label: name,
                accent: const Color(0xFF3F51B5).toSkirColor(),
                icon: skir.Icon.wrapIconify("material-symbols:map"),
              )
            : null,
      ),
    );
  }
}
