import "package:typewriter_panel/typewriter_panel.dart";

part "selectable.freezed.dart";

/// Describes an action or affordance available for one selectable.
///
/// Capabilities are data owned by the selectable. Selection operations inspect
/// the capabilities of every resolved item and expose a batch action only when
/// the selected items satisfy that action's requirements.
abstract class SelectionCapability {
  const SelectionCapability();
}

/// Stable identity for an item that can participate in panel selection.
///
/// The selection provider stores identifiers, not resolved selectable objects.
/// [create] resolves the current object through Riverpod and may report a
/// loading or error state while the underlying resource is unavailable.
abstract class SelectableIdentifier {
  const SelectableIdentifier();
  String get id;
  Object get resourceId => this;

  AsyncValue<Selectable> create(Ref ref);
}

/// Resolved presentation and operation data for a selected identifier.
///
/// A selectable is a current projection of its resource. It supplies the
/// display name and the capabilities that operations can use. Mutable editor
/// state remains with the resource and its owning application layer, rather
/// than with the selection list.
abstract class Selectable<I extends SelectableIdentifier> {
  const Selectable();

  I get id;
  String get name;

  /// What kind of thing this is, as the inspector counts several of them.
  SelectableNoun get noun;
  List<SelectionCapability> get capabilities;
}

/// The word for one kind of selectable, in the singular and the plural.
///
/// Selectables of one kind share an equal noun, so a selection of several
/// is counted by its kind ("2 members") or, when kinds differ, as [item].
@freezed
abstract class SelectableNoun with _$SelectableNoun {
  const factory SelectableNoun({required String one, required String many}) =
      _SelectableNoun;

  const SelectableNoun._();

  /// The noun a selection of mixed kinds is counted by.
  static const item = SelectableNoun(one: "item", many: "items");

  /// [count] of this kind, with the word that number takes: "1 member",
  /// "3 members".
  String count(int count) => "$count ${count == 1 ? one : many}";
}

/// Counting a selection by its kind.
extension SelectionNoun on Iterable<Selectable> {
  /// The one noun every item shares, or [SelectableNoun.item] when kinds
  /// differ.
  SelectableNoun get noun {
    final nouns = map((item) => item.noun).toSet();
    return nouns.length == 1 ? nouns.single : SelectableNoun.item;
  }
}
