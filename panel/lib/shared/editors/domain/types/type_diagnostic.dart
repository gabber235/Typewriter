import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "type_diagnostic.freezed.dart";

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

enum TypeDiagnosticSeverity { information, warning, error }

@freezed
abstract class TypeDiagnosticDetail with _$TypeDiagnosticDetail {
  const factory TypeDiagnosticDetail({
    required String key,
    required String value,
  }) = _TypeDiagnosticDetail;
}

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
