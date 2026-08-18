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

  const factory RealmAction.invokeCallback({
    required RealmActionId actionId,
    required TypedExpression payload,
  }) = InvokeRealmCallbackAction;
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
