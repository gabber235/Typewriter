import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SelectionEditorSource extends ChangeNotifier implements EditorSource {
  SelectionEditorSource(this._ref) {
    _ref.listen(inspectedSelectionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  @override
  TypeExpression? get rootType => _ref.read(inspectedRootTypeProvider);

  @override
  TypeRegistry? get registry {
    final selected = _ref.read(inspectedSelectionProvider).value;
    if (selected == null || selected.isEmpty) return null;
    return TypeRegistry(selected.mergedTypeCatalog);
  }

  @override
  EditorValue value(DataPath path) {
    final inspected = _ref.read(inspectedSelectionProvider);
    if (inspected.isLoading) return const EditorValue.loading();

    final selection = inspected.value;
    if (selection == null || selection.isEmpty) {
      return EditorValue.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "No values are selected",
        ),
      ]);
    }

    final values = selection
        .map((selectable) => selectable.value(path))
        .toList();
    final diagnostics = values
        .whereType<InvalidEditorValue>()
        .expand((state) => state.diagnostics)
        .toList();
    if (diagnostics.isNotEmpty) return EditorValue.invalid(diagnostics);
    if (values.any((state) => state is LoadingEditorValue)) {
      return const EditorValue.loading();
    }
    if (values.any((state) => state is! ReadyEditorValue)) {
      return const EditorValue.conflict();
    }

    final readyValues = values.cast<ReadyEditorValue>();
    final first = readyValues.first.value;
    if (readyValues.skip(1).any((state) => state.value != first)) {
      return const EditorValue.conflict();
    }
    return EditorValue.ready(first);
  }

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final selection = _ref.read(inspectedSelectionProvider).value ?? [];
    final validation = selection
        .map((selectable) => selectable.validateUpdate(path, value))
        .aggregateFor(path);
    if (validation is! AppliedEditorMutation) return validation;
    for (final selectable in selection) {
      selectable.update(path, value);
    }
    return validation;
  }
}

extension on Iterable<EditorMutationResult> {
  EditorMutationResult aggregateFor(DataPath path) {
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
