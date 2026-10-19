import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Exposes typed local values and reversible interaction to presentation.
///
/// Owners validate writes and notify listeners when their observable state
/// changes. Resource drafts, revision tracking and save policy stay with the
/// underlying editing workspace. A borrowed view may delegate to that owner,
/// so disposing this interface need not dispose the resource draft.
abstract interface class EditOwner implements Listenable {
  /// Describes the type used to validate values exposed by this owner.
  skir.TypeUse get rootType;

  /// Provides the catalog required to interpret [rootType].
  CheckedEditorCatalog get catalog;

  /// Whether edits are currently rejected instead of applied locally.
  bool get readOnly;

  /// Reads the local draft at [path], not necessarily the canonical resource.
  EditorValue value(skir.ValuePath path);

  /// Validates an edit without changing the local draft.
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value);

  /// Applies a validated edit to the local draft.
  ///
  /// The result is typed so invalid input cannot be mistaken for an applied
  /// change.
  EditorMutationResult update(skir.ValuePath path, skir.DataValue value);

  /// Opens a reversible interaction whose lifetime ends with its session.
  ///
  /// Sessions gate their owner's save policy while the interaction is active.
  /// [EditorInteractionSession.commit] and [EditorInteractionSession.cancel]
  /// define how the interaction leaves its local draft boundary.
  EditorInteractionSession beginInteraction(skir.ValuePath path);

  /// Releases listeners, interaction gates, and other owned resources.
  void dispose();
}
