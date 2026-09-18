import "package:freezed_annotation/freezed_annotation.dart";
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
  const factory EditorValue.invalid(List<TypeDiagnostic> diagnostics) =
      InvalidEditorValue;
  const factory EditorValue.ready(DataValue value) = ReadyEditorValue;

  DataValue? get valueOrNull => switch (this) {
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

  const factory EditorMutationResult.applied(DataValue value) =
      AppliedEditorMutation;
  const factory EditorMutationResult.conflict() = ConflictingEditorMutation;
  const factory EditorMutationResult.invalid(List<TypeDiagnostic> diagnostics) =
      InvalidEditorMutation;
}

/// Reads [path] without manufacturing a fallback when the path is unavailable.
extension DataValueEditorReading on DataValue {
  EditorValue readEditorValue(DataPath path) {
    final result = path.read(this);
    return switch (result) {
      TypeSuccess(:final value) => EditorValue.ready(value),
      TypeFailure(:final diagnostics) => EditorValue.invalid(diagnostics),
    };
  }
}

/// Validates one editor value against the type resolved at its path.
///
/// Resolution and value validation stay together so callers receive one typed
/// result before changing a draft. A registry is required when the expression
/// contains named types whose definitions are outside the expression itself.
extension TypeExpressionEditorMutationValidation on TypeExpression {
  EditorMutationResult validateEditorMutation(
    DataPath path,
    DataValue value, {
    TypeRegistry? registry,
  }) {
    final resolved = resolvePath(path, registry: registry);
    if (resolved case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    final diagnostics = value.validateAgainst(
      (resolved as TypeSuccess<TypeExpression>).value,
      path: path,
      registry: registry,
    );
    return diagnostics.isEmpty
        ? EditorMutationResult.applied(value)
        : EditorMutationResult.invalid(diagnostics);
  }
}
