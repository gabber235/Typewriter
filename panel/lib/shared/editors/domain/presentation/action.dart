/// Contracts for editing values locally and requesting work from the Realm.
///
/// Presentation controls create [EditorAction] values and the presentation
/// protocol routes them either through local execution or its Realm boundary.
/// Local execution returns a new editor value, while Realm results describe
/// instructions, authorization, diagnostics, or a stale catalog generation.
library;

import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "action.freezed.dart";

/// An action initiated by a presentation control.
///
/// The variant selects ownership of execution. Local actions mutate the
/// current binding environment. Realm actions are requests whose execution and
/// authorization remain with the Realm.
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

/// Outcome of invoking a Realm capability from an editor presentation.
///
/// A successful command carries panel instructions to apply after the Realm
/// accepts the request. Invalid and unavailable outcomes preserve diagnostics;
/// permission and generation failures tell the caller whether to report the
/// denial or refresh its catalog before retrying.
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

/// A UI side effect returned by a successful Realm command.
///
/// Instructions are interpreted by the editor host. They do not own resource
/// state: invalidation asks the owning editor to refresh, opening delegates to
/// the resource router, and notification delegates to the panel shell.
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

/// Outcome of evaluating a computation owned by the Realm.
///
/// Unlike [RealmCommandResult], success contains a value rather than panel
/// instructions. Callers must keep invalid, unavailable, permission, and stale
/// generation outcomes distinct because recovery belongs to different owners.
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

/// The protocol result for applying a typed mutation to Realm state.
///
/// Success confirms the applied value and revision. Conflict exposes the
/// current value so the editor can reconcile instead of overwriting it.
/// Invalid, unavailable, and permission outcomes are actionable failures.
/// Uncertain means transport completion was not observed; callers may use
/// [MutationUncertain.replay] when the operation is safe to replay.
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

  const factory TypedMutationResult.uncertain({
    required String message,
    required Object cause,
    required StackTrace stackTrace,
    Future<TypedMutationResult> Function()? replay,
    Object? submissionId,
  }) = MutationUncertain;

  @Assert("diagnostics.isNotEmpty", "Diagnostics must not be empty.")
  factory TypedMutationResult.unavailable(List<TypeDiagnostic> diagnostics) =
      MutationUnavailable;
}

/// Result of applying an action to the current local binding environment.
///
/// Local application either returns the root value for the changed binding or
/// diagnostics. It does not claim Realm persistence or assign a server
/// revision; the editor host decides whether and how to submit the new value.
@freezed
sealed class LocalMutationResult with _$LocalMutationResult {
  const factory LocalMutationResult.applied({
    required BindingId bindingId,
    required DataValue value,
  }) = LocalMutationApplied;
  const factory LocalMutationResult.invalid(List<TypeDiagnostic> diagnostics) =
      LocalMutationInvalid;
}
