import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The interactive card a search result draws on: an icon tile, the title
/// and its description, and the kind with its shortcut. Clicking selects
/// it; without a tap action it stays inert.
@widgetbook.UseCase(name: "Default", type: SearchResultCard)
Widget searchResultCardUseCase(BuildContext context) {
  final row = context.knobs.object.segmented(
    label: "Row",
    options: const ["Idle", "Focused", "Selected", "Disabled"],
    initialOption: "Idle",
  );
  final long = context.knobs.boolean(label: "Long name");
  final width = context.knobs.width(const {"Wide": 560, "Narrow": 260});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: _SelectableCard(
          initiallySelected: row == "Selected",
          focused: row == "Focused",
          enabled: row != "Disabled",
          title: long
              ? "Arrival at the gates of the old village after the long "
                    "winter journey across the frozen mountains"
              : "Meet the Mayor",
          description: long
              ? "The Lost Village. Act 1. Chapter 3. Where the traveller "
                    "first hears about the mill"
              : "The Lost Village. Act 1",
          kind: long ? "Conditional dialogue page" : "page",
        ),
      ),
    ),
  );
}

/// A card that turns selected when clicked, as a search palette selects.
class _SelectableCard extends HookWidget {
  const _SelectableCard({
    required this.initiallySelected,
    required this.focused,
    required this.enabled,
    required this.title,
    required this.description,
    required this.kind,
  });

  final bool initiallySelected;
  final bool focused;
  final bool enabled;
  final String title;
  final String description;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final selected = useState(initiallySelected);
    const accent = Color(0xff3f51b5);
    return SearchResultCard(
      color: accent,
      selected: selected.value,
      focused: focused,
      onTap: enabled ? () => selected.value = !selected.value : null,
      prefix: SearchResultIconTile(
        color: accent,
        onColor: accent.on(context),
        icon: const Icon(Icons.article_outlined),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: title),
          SearchResultDescription(description: description),
        ],
      ),
      suffix: SearchResultSuffix(
        label: kind,
        shortcutActivator: AdaptiveSingleActivator(
          LogicalKeyboardKey.digit1,
          control: true,
        ),
        selected: selected.value,
      ),
    );
  }
}
