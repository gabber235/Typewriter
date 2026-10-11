import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Immutable document and validation context from one resource revision.
///
/// Editor owners use a snapshot to keep canonical content, revision metadata,
/// and resource specific validation aligned while a commit is prepared. The
/// resource implementation supplies the admission policy used for every edit.

abstract class EditorSnapshot {
  const EditorSnapshot();

  /// Canonical content and metadata observed at one resource revision.
  EditorDocument get document;

  /// Applies resource specific validation to the complete local draft.
  List<EditorDiagnostic> validateDraft(skir.DataValue value) {
    final result = validate(editorRootPath, value);
    return switch (result) {
      InvalidEditorMutation(:final diagnostics) => diagnostics,
      _ => const [],
    };
  }

  /// Validates one path and value against the snapshot's type context.
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value);
}

/// Marks a snapshot whose interpretation contract can change independently.
///
/// The editor owner pins the installed snapshot. A replacement is accepted
/// immediately only when [contractCompatibleWith] proves that the existing
/// draft keeps the same meaning. Incompatible replacements stay pending until
/// the user reconciles or discards the draft explicitly.
abstract interface class EditorContractSnapshot implements EditorSnapshot {
  bool contractCompatibleWith(EditorSnapshot candidate);
}

/// Reports that an exact resource contract cannot currently be loaded.
final class EditorContractUnavailableException implements Exception {
  const EditorContractUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
