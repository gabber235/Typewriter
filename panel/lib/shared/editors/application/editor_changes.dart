import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Computes the smallest leaf changes needed to transform one editor value.
///
/// Record fields are compared recursively when both values retain the same
/// shape. A changed value, removed field, or type change is represented at the
/// current path so the result can be applied as editor mutations.
Map<skir.ValuePath, skir.DataValue> editorValueChanges(
  skir.DataValue before,
  skir.DataValue after, [
  skir.ValuePath? at,
]) {
  final path = at ?? editorRootPath;
  if (before == after) return const {};
  final beforeRecord = before.authoredRecord;
  final afterRecord = after.authoredRecord;
  final beforeFields = {
    for (final field in beforeRecord?.fields ?? const <skir.FieldValue>[])
      field.name: field.value,
  };
  final afterFields = {
    for (final field in afterRecord?.fields ?? const <skir.FieldValue>[])
      field.name: field.value,
  };
  if (beforeRecord != null &&
      afterRecord != null &&
      beforeFields.keys.toSet().containsAll(afterFields.keys) &&
      beforeFields.length == afterFields.length) {
    return {
      for (final entry in afterFields.entries)
        ...editorValueChanges(
          beforeFields[entry.key]!,
          entry.value,
          path.field(entry.key),
        ),
    };
  }
  return {path: after};
}

/// Applies a prepared value change set through the editor's normal contract.
///
/// Validation runs for every path before any update is made. If validation
/// succeeds, all local changes are applied and persistence is flushed through
/// the source's configured commit policy. This makes callers receive one
/// result without bypassing draft ownership or save lifecycle handling.
extension EditorChanges on EditorSource {
  Future<TypedMutationResult> applyChanges(
    Map<skir.ValuePath, skir.DataValue> changes,
  ) async {
    for (final entry in changes.entries) {
      final validation = validate(entry.key, entry.value);
      if (validation case InvalidEditorMutation(:final diagnostics)) {
        return TypedMutationResult.invalid(diagnostics);
      }
    }
    for (final entry in changes.entries) {
      update(entry.key, entry.value);
    }
    return flush(paths: changes.keys.toSet());
  }
}
