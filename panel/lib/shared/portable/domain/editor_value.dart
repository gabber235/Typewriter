import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_value.freezed.dart";

/// Describes whether a path can currently provide one usable editor value.
///
/// [loading] means the source has not produced an observation. [missing]
/// means an editable creation draft has no value at this path yet. [mixed]
/// means selected owners disagree, and [invalid] preserves path diagnostics.
/// Only [ready] exposes a value through [valueOrNull].
@freezed
sealed class EditorValue with _$EditorValue {
  const EditorValue._();

  const factory EditorValue.loading() = LoadingEditorValue;
  const factory EditorValue.missing() = MissingEditorValue;
  const factory EditorValue.mixed() = MixedEditorValue;
  const factory EditorValue.invalid(List<EditorDiagnostic> diagnostics) =
      InvalidEditorValue;
  const factory EditorValue.ready(skir.DataValue value) = ReadyEditorValue;

  skir.DataValue? get valueOrNull => switch (this) {
    ReadyEditorValue(:final value) => value,
    LoadingEditorValue() ||
    MissingEditorValue() ||
    MixedEditorValue() ||
    InvalidEditorValue() => null,
  };
}

/// Reports whether a proposed local value entered an editor draft.
///
/// [applied] is local acceptance, not persistence. [conflict] means the owner
/// cannot safely apply the edit in its current state. [invalid] carries the
/// diagnostics that callers should show or use to correct the input.
@freezed
sealed class EditorMutationResult with _$EditorMutationResult {
  const EditorMutationResult._();

  const factory EditorMutationResult.applied(skir.DataValue value) =
      AppliedEditorMutation;
  const factory EditorMutationResult.conflict() = ConflictingEditorMutation;
  const factory EditorMutationResult.invalid(
    List<EditorDiagnostic> diagnostics,
  ) = InvalidEditorMutation;
}

/// Reads [path] without manufacturing a fallback when the path is unavailable.
extension CanonicalDataValueEditorReading on skir.DataValue {
  EditorValue readEditorValue(skir.ValuePath path) {
    return switch (readAt(path)) {
      PortablePathValue(:final value) => EditorValue.ready(value),
      PortablePathUnavailable(:final message) => EditorValue.invalid([
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidPath,
          message: message,
          path: path,
        ),
      ]),
    };
  }
}

/// Combines per owner validation or update results without hiding disagreement.
/// Invalid diagnostics take precedence over conflicts. An applied result is
/// valid only when at least one owner accepts the path and every applied owner
/// returns the same value.
extension SelectionEditorMutationAggregation on Iterable<EditorMutationResult> {
  EditorMutationResult aggregateEditorMutationsFor(skir.ValuePath path) {
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
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidPath,
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
