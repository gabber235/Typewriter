import "package:typewriter_panel/typewriter_panel.dart";

part "typed_mutation_result.freezed.dart";

/// The outcome of applying a typed mutation to an owned resource.
///
/// Success confirms the applied value and revision. Conflict exposes the
/// current value so the editor can reconcile it. Invalid, unavailable, and
/// permission outcomes remain distinct because each has different recovery.
/// Uncertain retains the exact replay operation when submission may have
/// succeeded but its response was not observed.
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

/// Creates a rejected mutation with one actionable diagnostic.
MutationInvalid invalidMutation(String message) => MutationInvalid([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
]);

/// Creates an unavailable mutation and records a deleted target when known.
MutationUnavailable unavailableMutation(
  String message, {
  bool targetDeleted = false,
}) => MutationUnavailable([
  TypeDiagnostic(
    code: TypeDiagnosticCode.invalidValue,
    message: message,
    details: targetDeleted
        ? const [TypeDiagnosticDetail(key: "editor.target", value: "deleted")]
        : const [],
  ),
]);
