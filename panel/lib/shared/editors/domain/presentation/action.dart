import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "action.freezed.dart";

@freezed
sealed class EditorAction with _$EditorAction {
  const factory EditorAction.local(LocalAction action) = LocalEditorAction;
  const factory EditorAction.realm(RealmAction action) = RealmEditorAction;
}

@freezed
sealed class LocalAction with _$LocalAction {
  const factory LocalAction.setValue({
    required BindingReference target,
    required TypedExpression value,
  }) = SetValueAction;

  const factory LocalAction.insertListItem({
    required BindingReference target,
    required TypedExpression index,
    required TypedExpression value,
  }) = InsertListItemAction;

  const factory LocalAction.removeListItem({
    required BindingReference target,
    required TypedExpression index,
  }) = RemoveListItemAction;

  const factory LocalAction.appendListItem({
    required BindingReference target,
    required TypedExpression value,
  }) = AppendListItemAction;

  const factory LocalAction.duplicateListItem({
    required BindingReference source,
  }) = DuplicateListItemAction;

  const factory LocalAction.reorderListItem({
    required BindingReference source,
    required TypedExpression newIndex,
  }) = ReorderListItemAction;

  const factory LocalAction.putMapEntry({
    required BindingReference target,
    required TypedExpression key,
    required TypedExpression value,
  }) = PutMapEntryAction;

  const factory LocalAction.removeMapEntry({
    required BindingReference target,
    required TypedExpression key,
  }) = RemoveMapEntryAction;

  const factory LocalAction.replaceConcreteType({
    required BindingReference target,
    required ResolvedTypeRef concreteType,
    required TypedExpression initialValue,
  }) = ReplaceConcreteTypeAction;
}

@freezed
sealed class RealmAction with _$RealmAction {
  const factory RealmAction.reload() = ReloadRealmAction;

  const factory RealmAction.invokeCommand({
    required CapabilityId capabilityId,
    required TypedExpression payload,
  }) = InvokeRealmCommandAction;
}

sealed class EditorActionResult {
  const EditorActionResult();
}

final class LocalEditorActionResult extends EditorActionResult {
  const LocalEditorActionResult(this.mutation, {this.structuralMutation});

  final TypedMutationResult mutation;
  final EditorStructuralMutation? structuralMutation;
}

final class RealmEditorActionResult extends EditorActionResult {
  const RealmEditorActionResult(this.command);

  final RealmCommandResult command;
}

sealed class RealmCommandResult {
  const RealmCommandResult();

  const factory RealmCommandResult.success(
    List<PanelInstruction> instructions,
  ) = RealmCommandSuccess;
  const factory RealmCommandResult.invalid(List<TypeDiagnostic> diagnostics) =
      RealmCommandInvalid;
  const factory RealmCommandResult.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = RealmCommandUnavailable;
  const factory RealmCommandResult.permissionDenied(String message) =
      RealmCommandPermissionDenied;
  const factory RealmCommandResult.staleGeneration(
    CatalogGeneration actualGeneration,
  ) = RealmCommandStaleGeneration;
}

final class RealmCommandSuccess extends RealmCommandResult {
  const RealmCommandSuccess(this.instructions);

  final List<PanelInstruction> instructions;
}

final class RealmCommandInvalid extends RealmCommandResult {
  const RealmCommandInvalid(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

final class RealmCommandUnavailable extends RealmCommandResult {
  const RealmCommandUnavailable(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

final class RealmCommandPermissionDenied extends RealmCommandResult {
  const RealmCommandPermissionDenied(this.message);

  final String message;
}

final class RealmCommandStaleGeneration extends RealmCommandResult {
  const RealmCommandStaleGeneration(this.actualGeneration);

  final CatalogGeneration actualGeneration;
}

sealed class PanelInstruction {
  const PanelInstruction();

  const factory PanelInstruction.invalidateResource(ResourceAddress resource) =
      InvalidateResourceInstruction;
  const factory PanelInstruction.openResource(ResourceAddress resource) =
      OpenResourceInstruction;
  const factory PanelInstruction.notify(
    NotificationSeverity severity,
    String message,
  ) = NotifyInstruction;
}

final class ResourceAddress {
  const ResourceAddress({required this.type, required this.identity});

  final ResolvedTypeRef type;
  final DataValue identity;
}

final class InvalidateResourceInstruction extends PanelInstruction {
  const InvalidateResourceInstruction(this.resource);

  final ResourceAddress resource;
}

final class OpenResourceInstruction extends PanelInstruction {
  const OpenResourceInstruction(this.resource);

  final ResourceAddress resource;
}

enum NotificationSeverity { info, success, warning, error }

final class NotifyInstruction extends PanelInstruction {
  const NotifyInstruction(this.severity, this.message);

  final NotificationSeverity severity;
  final String message;
}

sealed class RealmComputationResult {
  const RealmComputationResult();

  const factory RealmComputationResult.success(DataValue value) =
      RealmComputationSuccess;
  const factory RealmComputationResult.invalid(
    List<TypeDiagnostic> diagnostics,
  ) = RealmComputationInvalid;
  const factory RealmComputationResult.unavailable(
    List<TypeDiagnostic> diagnostics,
  ) = RealmComputationUnavailable;
  const factory RealmComputationResult.permissionDenied(String message) =
      RealmComputationPermissionDenied;
  const factory RealmComputationResult.staleGeneration(
    CatalogGeneration actualGeneration,
  ) = RealmComputationStaleGeneration;
}

final class RealmComputationSuccess extends RealmComputationResult {
  const RealmComputationSuccess(this.value);

  final DataValue value;
}

final class RealmComputationInvalid extends RealmComputationResult {
  const RealmComputationInvalid(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

final class RealmComputationUnavailable extends RealmComputationResult {
  const RealmComputationUnavailable(this.diagnostics);

  final List<TypeDiagnostic> diagnostics;
}

final class RealmComputationPermissionDenied extends RealmComputationResult {
  const RealmComputationPermissionDenied(this.message);

  final String message;
}

final class RealmComputationStaleGeneration extends RealmComputationResult {
  const RealmComputationStaleGeneration(this.actualGeneration);

  final CatalogGeneration actualGeneration;
}

@freezed
sealed class TypedMutationResult with _$TypedMutationResult {
  @Assert("revision >= 0", "Revision must not be negative.")
  const factory TypedMutationResult.success({
    required int revision,
    required DataValue value,
  }) = MutationSuccess;

  const factory TypedMutationResult.conflict({
    required int expectedRevision,
    required int actualRevision,
    required DataValue actualValue,
  }) = MutationConflict;

  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory TypedMutationResult.invalid(List<TypeDiagnostic> diagnostics) =
      MutationInvalid;

  const factory TypedMutationResult.permissionDenied(String message) =
      MutationPermissionDenied;

  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory TypedMutationResult.unavailable(List<TypeDiagnostic> diagnostics) =
      MutationUnavailable;
}
