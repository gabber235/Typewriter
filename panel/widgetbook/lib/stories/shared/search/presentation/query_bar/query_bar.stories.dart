import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Default", type: QueryBar)
Widget queryBarDefaultUseCase(BuildContext context) {
  final initial = context.knobs.string(
    label: "Query",
    initialValue: "kind:book tag:quest village",
  );
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 520,
    min: 240,
    max: 900,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: _QueryBarStory(key: ValueKey(initial), initial: initial),
      ),
    ),
  );
}

/// A query bar that keeps what the user types, starting from [initial].
class _QueryBarStory extends HookWidget {
  const _QueryBarStory({required this.initial, super.key});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final query = useState(initial);
    return QueryBar(
      query: query.value,
      selectors: mockQuerySelectors,
      onQueryChanged: (next) => query.value = next,
    );
  }
}
