import "package:typewriter_panel/typewriter_panel.dart";

/// A selection one [SelectionSurface] owns instead of the page selection,
/// such as the values a list picker holds.
///
/// The [Selector]s of that surface keep every gesture of the shared model
/// and send each one here instead of to [Selection]: a plain click or Enter
/// calls [choose], Command or Control+click and Space call [toggle], Shift
/// with a click or an arrow calls [selectRange], and select all calls
/// [selectEvery]. The owner decides what each gesture means for its items
/// and notifies listeners when the selected items change. The page
/// selection, its operations and its clearing stay untouched.
abstract interface class SurfaceSelection implements Listenable {
  /// Whether [item] is selected.
  bool contains(SelectableIdentifier item);

  /// Whether the items show their check.
  bool get showsChecks;

  /// A plain click on [item], or Enter while it has focus.
  void choose(SelectableIdentifier item);

  /// Command or Control+click on [item], or Space while it has focus.
  void toggle(SelectableIdentifier item);

  /// Shift with a click or an arrow reaching [to]. [order] is the surface's
  /// visible order, and [from] the item focus left, when an arrow moved it.
  void selectRange(
    SelectableIdentifier to, {
    required List<SelectableIdentifier> order,
    SelectableIdentifier? from,
  });

  /// Select all over [order], every item of the surface.
  void selectEvery(List<SelectableIdentifier> order);
}
