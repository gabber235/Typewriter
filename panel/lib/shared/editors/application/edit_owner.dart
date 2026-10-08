import "package:typewriter_panel/typewriter_panel.dart";

/*
 * Editing is deliberately owned separately from persistence.
 *
 * The owner exposes the current local value and preserves its invariants while
 * presentation code edits it. A transactional implementation may also own a
 * canonical resource snapshot, a local draft, revision tracking, persistence
 * attempts, and reconciliation, but those states remain distinct. Callers must
 * use the operations here instead of mutating a value or coordinating saves
 * themselves. Implementations notify listeners after an observable state
 * change and release all owned interaction state from dispose.
 */

/// Owns mutable typed values and reversible interactions, independently of
/// saving.
abstract interface class EditOwner implements Listenable {
  /// Describes the type used to validate values exposed by this owner.
  TypeExpression get rootType;

  /// Provides the catalog required to interpret [rootType].
  TypeCatalog get typeCatalog;

  /// Whether edits are currently rejected instead of applied locally.
  bool get readOnly;

  /// Reads the local draft at [path], not necessarily the canonical resource.
  EditorValue value(DataPath path);

  /// Validates an edit without changing the local draft.
  EditorMutationResult validate(DataPath path, DataValue value);

  /// Applies a validated edit to the local draft.
  ///
  /// The result is typed so invalid input cannot be mistaken for an applied
  /// change. Structural metadata is retained when supplied, allowing an owner
  /// to preserve the operation for later persistence or reconciliation.
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  });

  /// Opens a reversible interaction whose lifetime ends with its session.
  ///
  /// Implementations serialize overlapping interactions and keep their
  /// ownership local. Closing the session restores or commits according to the
  /// interaction contract, without making persistence implicit for callers.
  EditorInteractionSession beginInteraction(DataPath path);

  /// Releases listeners, interaction gates, and other owned resources.
  void dispose();
}
