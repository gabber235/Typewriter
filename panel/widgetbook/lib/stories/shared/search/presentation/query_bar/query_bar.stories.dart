import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The query field of every search: selectors such as `kind:` and `#` are
/// highlighted and completed as the user types. While the first results
/// load a thin bar runs along its bottom edge; a value the source rejects
/// shows under the field.
///
/// Reduced motion is left out: under it the bar throws "RenderAnimatedSize
/// was mutated in its own performLayout" (query_bar_view.dart:13).
@widgetbook.UseCase(name: "Default", type: QueryBar)
Widget queryBarDefaultUseCase(BuildContext context) {
  final initial = context.knobs.string(
    label: "Query",
    initialValue: "kind:book tag:quest village",
  );
  final state = context.knobs.object.segmented(
    label: "State",
    options: const [
      "Idle",
      "Loading",
      "Rejected value",
      "Disabled",
      "Read only",
    ],
    initialOption: "Idle",
  );
  final width = context.knobs.width(const {"Wide": 520, "Narrow": 240});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: _QueryBarStory(
          key: ValueKey((initial, state)),
          initial: initial,
          state: state,
        ),
      ),
    ),
  );
}

/// A query bar in [state] that keeps what the user types, starting from
/// [initial].
class _QueryBarStory extends HookWidget {
  const _QueryBarStory({required this.initial, required this.state, super.key});

  final String initial;
  final String state;

  @override
  Widget build(BuildContext context) {
    final query = useState(initial);
    return QueryBar(
      query: query.value,
      selectors: mockQuerySelectors,
      onQueryChanged: (next) => query.value = next,
      loadingLabel: state == "Loading" ? "Loading results" : null,
      validationIssues: [
        if (state == "Rejected value")
          const QueryParseIssue(
            code: QueryIssueCode.invalidSelectorValue,
            severity: QuerySeverity.error,
            message: "No tag is named quest. Pick a tag from the list.",
          ),
      ],
      enabled: state != "Disabled",
      readOnly: state == "Read only",
    );
  }
}
