import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_value.freezed.dart";

@freezed
sealed class EditorValue with _$EditorValue {
  const EditorValue._();

  const factory EditorValue.loading() = LoadingEditorValue;
  const factory EditorValue.conflict() = ConflictEditorValue;
  const factory EditorValue.invalid(List<TypeDiagnostic> diagnostics) =
      InvalidEditorValue;
  const factory EditorValue.ready(DataValue value) = ReadyEditorValue;

  DataValue? get valueOrNull => switch (this) {
    ReadyEditorValue(:final value) => value,
    LoadingEditorValue() ||
    ConflictEditorValue() ||
    InvalidEditorValue() => null,
  };
}

@freezed
sealed class EditorMutationResult with _$EditorMutationResult {
  const EditorMutationResult._();

  const factory EditorMutationResult.applied(DataValue value) =
      AppliedEditorMutation;
  const factory EditorMutationResult.conflict() = ConflictingEditorMutation;
  const factory EditorMutationResult.invalid(List<TypeDiagnostic> diagnostics) =
      InvalidEditorMutation;
}

extension DataValueEditorReading on DataValue {
  EditorValue readEditorValue(DataPath path) {
    final result = path.read(this);
    return switch (result) {
      TypeSuccess(:final value) => EditorValue.ready(value),
      TypeFailure(:final diagnostics) => EditorValue.invalid(diagnostics),
    };
  }
}

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
