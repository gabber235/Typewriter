import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Appearance and state", type: SearchResultRow)
Widget searchResultRowUseCase(BuildContext context) {
  final card = context.knobs.boolean(label: "Card", initialValue: true);
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final selected = context.knobs.boolean(label: "Selected");
  final focused = context.knobs.boolean(label: "Focused", initialValue: true);
  final loading = context.knobs.boolean(label: "Loading");
  final width = context.knobs.double.slider(
    label: "Width", initialValue: 360, min: 240, max: 760,
  );
  final scale = context.knobs.double.slider(
    label: "Text scale", initialValue: 1, min: 1, max: 2,
  );
  const result = SearchResult(
    id: "shell.story",
    type: SearchResultType(id: "story", rowRendererId: "story.row", label: "Story"),
    payload: "story",
    title: "Meet the Mayor",
  );
  return FakeApp(
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: Center(
          child: SizedBox(
            width: width,
            child: SearchResultRow(
              row: SearchResultRowContext(
                result: result,
                selected: selected,
                focused: focused,
                loading: loading,
                onTap: enabled ? () {} : null,
                shortcutActivator: const SingleActivator(LogicalKeyboardKey.enter),
              ),
              density: card ? SearchResultDensity.card : SearchResultDensity.compact,
              accent: Colors.purple,
              leading: const Icon(Icons.article_outlined),
              kindLabel: "page",
              body: const SearchResultTitle(title: "Meet the Mayor"),
              footer: const SearchResultDescription(description: "Main Quest. Village"),
            ),
          ),
        ),
      ),
    ),
  );
}
