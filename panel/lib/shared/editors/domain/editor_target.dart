import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Presents one resource snapshot to editor composition and interaction code.
///
/// Targets bind a stable resource identity and label to the snapshot used for
/// initial reads and validation. [value] reads confirmed content for the
/// initial presentation, while an [EditOwner] later exposes the local draft.
/// [commitPolicy] tells that owner whether local changes autosave or wait for
/// an explicit resource apply. The target does not own mutable draft state.
abstract interface class EditorTarget {
  Object get targetId;
  String get label;
  EditableResource get resource;
  EditorSnapshot get snapshot;
  EditorDocument get document;
  EditorCommitPolicy get commitPolicy;

  /// Validates the complete draft against resource level rules.
  List<EditorDiagnostic> validateDraft(skir.DataValue value);

  /// Reads confirmed target content before an editing owner is attached.
  EditorValue value(skir.ValuePath path);

  /// Checks one proposed value without changing target or owner state.
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value);
}
