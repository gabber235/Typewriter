import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates an editor's local draft with an optional canonical document and
/// persistence boundary.
///
/// Implementations expose draft state through [EditOwner], while this contract
/// adds the lifecycle needed by resource backed editors: remote revisions can
/// arrive independently, local edits can be discarded or reconciled, and
/// [flush] reports persistence rather than implying it succeeded. A caller
/// chooses [useRemote] or [keepLocal] when a remote change conflicts with the
/// draft; neither choice is implicit.
abstract interface class EditorSource implements EditOwner {
  /// The latest canonical observation, or null for a draft only editor.
  EditorDocument? get document;

  /// Defines how callers should place and interpret persistence commits.
  EditorCommitPolicy get commitPolicy;

  /// Whether the draft contains work that a flush could persist.
  bool get hasWork;

  /// Diagnostics attached to the current draft rather than the remote document.
  List<EditorDiagnostic> get draftDiagnostics;

  /// Removes local edits and returns the editor to its canonical observation.
  void discardDraft();

  @override
  EditorValue value(skir.ValuePath path);

  @override
  EditorMutationResult update(
    skir.ValuePath path,
    skir.DataValue value, {
    EditorStructuralMutation? structuralMutation,
  });

  /// Replaces the canonical observation and reconciles any local draft against
  /// it according to the editor's merge policy.
  void refreshDocument(EditorDocument document);

  @override
  EditorInteractionSession beginInteraction(skir.ValuePath path);

  /// Describes whether [path] is clean, locally changed, conflicted, or ready
  /// for the next save operation.
  EditorSaveState saveState(skir.ValuePath path);

  /// Captures and submits pending edits for [paths], or all changed paths.
  /// The typed result reports rejection and transport failure to the caller.
  Future<TypedMutationResult> flush({Set<skir.ValuePath>? paths});

  /// Replaces the canonical value and revision when the remote resource exists.
  void acceptRemote({required int revision, required skir.DataValue value});

  /// Records that the canonical resource no longer exists.
  void acceptRemoteDeletion();

  /// Resolves [path] in favor of the canonical value, discarding its draft.
  void useRemote(skir.ValuePath path);

  /// Resolves [path] in favor of the draft by persisting it against the remote
  /// revision.
  Future<TypedMutationResult> keepLocal(skir.ValuePath path);

  @override
  void dispose();
}
