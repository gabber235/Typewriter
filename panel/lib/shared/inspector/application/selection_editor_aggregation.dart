import "package:typewriter_panel/typewriter_panel.dart";

TypedMutationResult aggregateSelectionResults(
  List<TypedMutationResult> results,
) {
  if (results.isEmpty) {
    return TypedMutationResult.unavailable([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "No inspected selection is available",
      ),
    ]);
  }
  for (final result in results) {
    if (result is! MutationSuccess) return result;
  }
  final success = results.cast<MutationSuccess>().first;
  return TypedMutationResult.success(
    revision: success.revision,
    value: success.value,
  );
}

int selectionSavePriority(EditorSavePhase phase) => switch (phase) {
  EditorSavePhase.deletedElsewhere => 9,
  EditorSavePhase.conflict => 8,
  EditorSavePhase.repeatedContention => 7,
  EditorSavePhase.failed => 6,
  EditorSavePhase.saving => 5,
  EditorSavePhase.pending => 4,
  EditorSavePhase.sessionOnly => 3,
  EditorSavePhase.saved => 2,
  EditorSavePhase.idle => 1,
};

extension SelectionEditorMutationAggregation on Iterable<EditorMutationResult> {
  EditorMutationResult aggregateEditorMutationsFor(DataPath path) {
    final results = toList();
    final diagnostics = results
        .whereType<InvalidEditorMutation>()
        .expand((result) => result.diagnostics)
        .toList();
    if (diagnostics.isNotEmpty) {
      return EditorMutationResult.invalid(diagnostics);
    }
    if (results.any((result) => result is ConflictingEditorMutation)) {
      return const EditorMutationResult.conflict();
    }
    final applied = results.whereType<AppliedEditorMutation>().toList();
    if (applied.isEmpty) {
      return EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "No inspected selection can accept the mutation",
          path: path,
        ),
      ]);
    }
    final accepted = applied.first.value;
    if (applied.skip(1).any((result) => result.value != accepted)) {
      return const EditorMutationResult.conflict();
    }
    return EditorMutationResult.applied(accepted);
  }
}
