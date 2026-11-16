import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _longTitle =
    "Arrival at the gates of the old village after the long winter journey "
    "across the frozen mountains";

/// One result part at the width the Width knob picks.
Widget _part(BuildContext context, Widget part) {
  final width = context.knobs.width(const {"Row": 360, "Narrow": 160});
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: Align(alignment: Alignment.centerLeft, child: part),
      ),
    ),
  );
}

/// The icon tile at the start of a result, in a Page's accent.
@widgetbook.UseCase(name: "Default", type: SearchResultIconTile)
Widget searchResultIconTileUseCase(BuildContext context) {
  final accent = context.knobs.object.segmented(
    label: "Accent",
    options: const ["Page", "Realm", "Danger"],
    initialOption: "Page",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          final color = switch (accent) {
            "Realm" => realmServiceRoleColor,
            "Danger" => context.colors.danger,
            _ => const Color(0xff3f51b5),
          };
          return SearchResultIconTile(
            color: color,
            onColor: color.on(context),
            icon: const Icon(Icons.article_outlined),
          );
        },
      ),
    ),
  );
}

/// A result's title: deprecated results strike it through, and a command
/// running on the result ripples its letters.
@widgetbook.UseCase(name: "Default", type: SearchResultTitle)
Widget searchResultTitleUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long name");
  final deprecated = context.knobs.boolean(label: "Deprecated");
  final working = context.knobs.boolean(label: "Working");
  return _part(
    context,
    SearchResultTitle(
      title: long ? _longTitle : "Meet the Mayor",
      deprecated: deprecated,
      working: working,
    ),
  );
}

/// The line under a result's title, cut to one line.
@widgetbook.UseCase(name: "Default", type: SearchResultDescription)
Widget searchResultDescriptionUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long description");
  return _part(
    context,
    SearchResultDescription(
      description: long
          ? "Act 1. Chapter 3. The part where the traveller first meets the "
                "mayor and hears about the mill"
          : "The Lost Village. Act 1",
    ),
  );
}

/// A small soft chip a result shows beside its title, such as a tag.
@widgetbook.UseCase(name: "Default", type: SearchResultSoftChip)
Widget searchResultSoftChipUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long label");
  return Story(
    const [],
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          return SearchResultSoftChip(
            label: long ? "Main story of the northern villages" : "Quest",
            backgroundColor: context.colors.brandContainer,
            foregroundColor: context.colors.contentPrimary,
          );
        },
      ),
    ),
  );
}

/// The kind of a result, in capitals and cut to one line.
@widgetbook.UseCase(name: "Default", type: SearchResultTypeLabel)
Widget searchResultTypeLabelUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long kind");
  return _part(
    context,
    SearchResultTypeLabel(
      label: long ? "Conditional dialogue option entry definition" : "Page",
    ),
  );
}

/// The end of a result row: its kind, and the shortcut that opens it, which
/// turns outlined while the row is selected.
@widgetbook.UseCase(name: "Default", type: SearchResultSuffix)
Widget searchResultSuffixUseCase(BuildContext context) {
  final long = context.knobs.boolean(label: "Long kind");
  final shortcut = context.knobs.boolean(label: "Shortcut", initialValue: true);
  final selected = context.knobs.boolean(label: "Selected");
  return _part(
    context,
    SearchResultSuffix(
      label: long ? "Conditional dialogue option entry definition" : "Page",
      shortcutActivator: shortcut
          ? AdaptiveSingleActivator(LogicalKeyboardKey.digit1, control: true)
          : null,
      selected: selected,
    ),
  );
}
