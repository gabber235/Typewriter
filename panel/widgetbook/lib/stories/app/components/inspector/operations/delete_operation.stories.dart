import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/app/components/inspector/operations/operations.stories.dart";

@widgetbook.UseCase(name: "Single Success", type: DeleteOperationButton)
Widget deleteSingleSuccessUseCase(BuildContext context) {
  return operationUseCase(context, [
    (ctx) => _DeleteSelectableIdentifier(
      "test",
      onDelete: () => delayedSnack(ctx, delay: 1.seconds, text: "Deleted"),
    ),
  ]);
}

@widgetbook.UseCase(
  name: "Multiple Success",
  type: DeleteOperationButton,
)
Widget deleteMultipleSuccessUseCase(BuildContext context) {
  return operationUseCase(context, [
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

@widgetbook.UseCase(
  name: "Partial Failures",
  type: DeleteOperationButton,
)
Widget deletePartialFailureUseCase(BuildContext context) {
  return operationUseCase(context, [
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

class _DeleteSelectable extends Selectable<_DeleteSelectableIdentifier> {
  _DeleteSelectable({required this.id, required this.onDelete});

  @override
  final _DeleteSelectableIdentifier id;

  @override
  ObjectBlueprint get objectBlueprint => ObjectBlueprint(fields: {});

  @override
  String get name => id.id.titleCase();

  final FutureOr<void> Function() onDelete;

  @override
  List<SelectableOperation> get operations => [
    DeleteSelectableOperation(onDelete: onDelete),
  ];

  @override
  Widget? header() => null;

  @override
  dynamic fieldValue(String path) => null;

  @override
  void setFieldValue(String path, dynamic value) {}

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
