import "package:typewriter_panel/typewriter_panel.dart";

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
  List<SelectionCapability> get capabilities;
}
