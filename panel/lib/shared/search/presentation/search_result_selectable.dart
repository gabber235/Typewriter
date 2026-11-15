import "package:typewriter_panel/typewriter_panel.dart";

/// A search result as an item of a [SelectionSurface] that owns its
/// selection, such as a list picker's results. Two results with one id are
/// one item.
final class SearchResultSelectable extends SelectableIdentifier {
  const SearchResultSelectable(this.result);

  final SearchResult result;

  @override
  String get id => result.id;

  @override
  AsyncValue<Selectable> create(Ref ref) => AsyncData(_SearchResultItem(this));

  @override
  bool operator ==(Object other) =>
      other is SearchResultSelectable && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class _SearchResultItem extends Selectable<SearchResultSelectable> {
  const _SearchResultItem(this.id);

  @override
  final SearchResultSelectable id;

  @override
  String get name => id.result.title ?? id.result.id;

  @override
  SelectableNoun get noun =>
      const SelectableNoun(one: "result", many: "results");

  @override
  List<SelectionCapability> get capabilities => const [];
}
