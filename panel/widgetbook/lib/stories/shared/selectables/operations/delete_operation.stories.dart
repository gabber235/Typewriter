import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/selectables/operations/operation_story.dart";

@widgetbook.UseCase(name: "Single Success", type: DeleteOperationButton)
Widget deleteSingleSuccessUseCase(BuildContext context) {
  return operationStory(context, [
    (ctx) => _DeleteSelectableIdentifier(
      "test",
      onDelete: () => delayedSnack(ctx, delay: 1.seconds, text: "Deleted"),
    ),
  ]);
}

@widgetbook.UseCase(name: "Multiple Success", type: DeleteOperationButton)
Widget deleteMultipleSuccessUseCase(BuildContext context) {
  return operationStory(context, [
    (ctx) => _DeleteSelectableIdentifier(
      "alpha",
      onDelete: () => delayedSnack(ctx, delay: 500.ms, text: "Deleted alpha"),
    ),
    (ctx) => _DeleteSelectableIdentifier(
      "beta",
      onDelete: () => delayedSnack(ctx, delay: 700.ms, text: "Deleted beta"),
    ),
  ]);
}

@widgetbook.UseCase(name: "Partial Failures", type: DeleteOperationButton)
Widget deletePartialFailureUseCase(BuildContext context) {
  return operationStory(context, [
    (ctx) => _DeleteSelectableIdentifier(
      "success",
      onDelete: () => delayedSnack(ctx, delay: 400.ms, text: "Deleted success"),
    ),
    (ctx) => _DeleteSelectableIdentifier("fail-1"),
    (ctx) => _DeleteSelectableIdentifier(
      "fail-2",
      onDelete: () async {
        await Future.delayed(300.ms);
        throw DeleteOperationError("fail-2");
      },
    ),
  ]);
}

class _DeleteSelectableIdentifier extends SelectableIdentifier {
  _DeleteSelectableIdentifier(this.id, {this.onDelete});
  @override
  final String id;

  final FutureOr<void> Function()? onDelete;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    return AsyncValue.data(
      _DeleteSelectable(
        id: this,
        onDelete: onDelete ?? () => throw DeleteOperationError(id),
      ),
    );
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DeleteSelectableIdentifier && other.id == id;

  @override
  String toString() => "_TestSelectableIdentifier($id)";
}

class _DeleteSelectable
    extends InspectableSelectable<_DeleteSelectableIdentifier> {
  _DeleteSelectable({required this.id, required this.onDelete});

  static final TypeDefinition _rootDefinition = TypeDefinition(
    id: ResolvedTypeRef(
      id: QualifiedTypeId(namespace: "widgetbook", name: "delete_story"),
      revision: 1,
    ),
    kind: NominalTypeKind.concrete,
    representation: RecordType(fields: const {}),
  );

  static final TypeCatalog _typeCatalog = TypeCatalog([_rootDefinition]);

  @override
  final _DeleteSelectableIdentifier id;

  @override
  ResolvedTypeRef get rootType => _rootDefinition.id;

  @override
  TypeCatalog get typeCatalog => _typeCatalog;

  @override
  String get name => id.id.titleCase();

  final FutureOr<void> Function() onDelete;

  @override
  List<SelectionCapability> get capabilities => [
    DeleteSelectionCapability(onDelete: onDelete),
  ];

  @override
  Widget? buildInspectorHeader() => null;

  @override
  EditorValue value(DataPath path) => EditorValue.invalid([
    TypeDiagnostic(
      code: TypeDiagnosticCode.invalidPath,
      message: "The delete story has no editable fields",
      path: path,
    ),
  ]);

  @override
  EditorMutationResult update(DataPath path, DataValue value) =>
      EditorMutationResult.invalid([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPath,
          message: "The delete story has no editable fields",
          path: path,
        ),
      ]);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _DeleteSelectable && other.id == id;
}

class DeleteOperationError extends Error {
  DeleteOperationError(this.id);

  final String id;

  @override
  String toString() => "Failed to delete $id";
}
