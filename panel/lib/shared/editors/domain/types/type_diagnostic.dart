import "package:typewriter_panel/typewriter_panel.dart";

part "type_diagnostic.freezed.dart";

/// Machine readable reason for rejecting or qualifying type work.
enum TypeDiagnosticCode {
  ambiguousConversion,
  conflictingInheritance,
  conversionFailed,
  conversionNotFound,
  duplicateDefinition,
  evaluationBudgetExceeded,
  genericArity,
  genericBound,
  inheritanceCycle,
  incompatibleRepresentation,
  invalidConstraint,
  invalidExpression,
  invalidPath,
  invalidPresentation,
  invalidRevision,
  invalidTypeId,
  invalidConcreteType,
  invalidValue,
  missingField,
  mutationConflict,
  permissionDenied,
  unknownField,
  unknownType,
  varianceViolation,
  weakenedConstraint,
}

/// How strongly a caller should treat a diagnostic when presenting it.
enum TypeDiagnosticSeverity { information, warning, error }

/// A structured diagnostic value that preserves details for clients.
@freezed
abstract class TypeDiagnosticDetail with _$TypeDiagnosticDetail {
  const factory TypeDiagnosticDetail({
    required String key,
    required String value,
  }) = _TypeDiagnosticDetail;
}

/// A user facing type problem located within a value or type path.
///
/// Diagnostics are the recovery boundary for this domain. Callers can retain
/// all failures, present `path` and `details`, or translate `code` across the
/// editor protocol without parsing the message.
@freezed
abstract class TypeDiagnostic with _$TypeDiagnostic {
  const factory TypeDiagnostic({
    required TypeDiagnosticCode code,
    required String message,
    @Default(DataPath.root) DataPath path,
    ResolvedTypeRef? type,
    @Default(TypeDiagnosticSeverity.error) TypeDiagnosticSeverity severity,
    String? relatedType,
    @Default([]) List<TypeDiagnosticDetail> details,
    @Default(true) bool pathPresent,
  }) = _TypeDiagnostic;

  const TypeDiagnostic._();

  /// Prefixes this diagnostic when a nested validator returns it to its caller.
  TypeDiagnostic at(DataPath prefix) => TypeDiagnostic(
    code: code,
    message: message,
    path: prefix.followedBy(path),
    type: type,
    severity: severity,
    relatedType: relatedType,
    details: details,
    pathPresent: true,
  );

  @override
  String toString() => "${code.name} at $path: $message";
}

/// Either a value or one or more diagnostics explaining why it is unavailable.
///
/// A failure is never empty. This keeps validation, resolution, and refinement
/// callers from mistaking an absent value for a successful operation.
@freezed
sealed class TypeResult<T> with _$TypeResult<T> {
  const factory TypeResult.success(T value) = TypeSuccess<T>;

  @Assert("diagnostics.length > 0", "Diagnostics must not be empty.")
  factory TypeResult.failure(List<TypeDiagnostic> diagnostics) = TypeFailure<T>;

  const TypeResult._();

  T? get valueOrNull => switch (this) {
    TypeSuccess(:final value) => value,
    TypeFailure() => null,
  };

  List<TypeDiagnostic> get diagnostics => switch (this) {
    TypeSuccess() => const [],
    TypeFailure(:final diagnostics) => diagnostics,
  };
}
