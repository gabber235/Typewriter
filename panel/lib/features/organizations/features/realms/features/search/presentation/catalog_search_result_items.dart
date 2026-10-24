import "package:typewriter_panel/typewriter_panel.dart";

Widget buildAuthoringCreationSearchResultItem(SearchResultRowContext row) {
  final option = row.result.payload as AuthoringCreationOption;
  final display = option.display;
  final icon = display?.icon;
  final description = option.disabledReason ?? display?.description.trim();
  return SearchResultRow(
    row: row,
    density: SearchResultDensity.card,
    accent: display?.searchResultAccent,
    leading: icon?.iconValue == null
        ? const Icon(Icons.add)
        : ResourceIcon(icon: icon),
    kindLabel: "resource",
    title: option.label,
    footer: description == null || description.isEmpty
        ? null
        : SearchResultDescription(description: description),
  );
}
