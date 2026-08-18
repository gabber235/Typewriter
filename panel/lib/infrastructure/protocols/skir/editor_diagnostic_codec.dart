import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

extension TypeDiagnosticWireEncoding on TypeDiagnostic {
  wire.TypeDiagnostic encodeWire(SkirDataPathCodec paths) {
    final value = this;
    return wire.TypeDiagnostic(
      code: code._encodeWire,
      severity: switch (value.severity) {
        TypeDiagnosticSeverity.information =>
          wire.DiagnosticSeverity.information,
        TypeDiagnosticSeverity.warning => wire.DiagnosticSeverity.warning,
        TypeDiagnosticSeverity.error => wire.DiagnosticSeverity.error,
      },
      message: value.message,
      path: value.pathPresent ? paths.encode(value.path).valueOrNull : null,
      relatedType: value.relatedType ?? value.type?.toString(),
      details: [
        for (final detail in value.details)
          wire.DiagnosticDetail(key: detail.key, value: detail.value),
      ],
    );
  }
}

extension WireTypeDiagnosticDecoding on wire.TypeDiagnostic {
  TypeDiagnostic decodeWire(SkirDataPathCodec paths) {
    final value = this;
    return TypeDiagnostic(
      code: value.code._decodeDomain,
      severity: switch (value.severity) {
        wire.DiagnosticSeverity.information =>
          TypeDiagnosticSeverity.information,
        wire.DiagnosticSeverity.warning => TypeDiagnosticSeverity.warning,
        wire.DiagnosticSeverity.error || _ => TypeDiagnosticSeverity.error,
      },
      message: value.message,
      path: value.path == null
          ? DataPath.root
          : paths.decode(value.path).valueOrNull ?? DataPath.root,
      pathPresent: value.path != null,
      relatedType: value.relatedType,
      details: [
        for (final detail in value.details)
          TypeDiagnosticDetail(key: detail.key, value: detail.value),
      ],
    );
  }
}

extension on TypeDiagnosticCode {
  wire.DiagnosticCode get _encodeWire => switch (this) {
    TypeDiagnosticCode.invalidTypeId ||
    TypeDiagnosticCode.unknownType => wire.DiagnosticCode.invalidTypeId,
    TypeDiagnosticCode.invalidRevision => wire.DiagnosticCode.invalidRevision,
    TypeDiagnosticCode.duplicateDefinition =>
      wire.DiagnosticCode.duplicateDefinition,
    TypeDiagnosticCode.genericArity => wire.DiagnosticCode.invalidArity,
    TypeDiagnosticCode.genericBound => wire.DiagnosticCode.unsatisfiedBound,
    TypeDiagnosticCode.varianceViolation => wire.DiagnosticCode.invalidVariance,
    TypeDiagnosticCode.inheritanceCycle => wire.DiagnosticCode.inheritanceCycle,
    TypeDiagnosticCode.conflictingInheritance =>
      wire.DiagnosticCode.inheritanceConflict,
    TypeDiagnosticCode.weakenedConstraint ||
    TypeDiagnosticCode.invalidConstraint =>
      wire.DiagnosticCode.weakenedConstraint,
    TypeDiagnosticCode.incompatibleRepresentation =>
      wire.DiagnosticCode.incompatibleRepresentation,
    TypeDiagnosticCode.invalidValue => wire.DiagnosticCode.invalidValue,
    TypeDiagnosticCode.missingField => wire.DiagnosticCode.missingRequiredField,
    TypeDiagnosticCode.unknownField => wire.DiagnosticCode.unknownField,
    TypeDiagnosticCode.invalidPath => wire.DiagnosticCode.invalidPath,
    TypeDiagnosticCode.invalidConcreteType =>
      wire.DiagnosticCode.invalidConcreteType,
    TypeDiagnosticCode.conversionNotFound =>
      wire.DiagnosticCode.conversionNotFound,
    TypeDiagnosticCode.ambiguousConversion =>
      wire.DiagnosticCode.conversionAmbiguous,
    TypeDiagnosticCode.conversionFailed => wire.DiagnosticCode.conversionFailed,
    TypeDiagnosticCode.invalidExpression =>
      wire.DiagnosticCode.invalidExpression,
    TypeDiagnosticCode.evaluationBudgetExceeded =>
      wire.DiagnosticCode.evaluationBudgetExceeded,
    TypeDiagnosticCode.invalidPresentation =>
      wire.DiagnosticCode.invalidPresentation,
    TypeDiagnosticCode.mutationConflict => wire.DiagnosticCode.mutationConflict,
    TypeDiagnosticCode.permissionDenied => wire.DiagnosticCode.permissionDenied,
  };
}

extension on wire.DiagnosticCode {
  TypeDiagnosticCode get _decodeDomain => switch (this) {
    wire.DiagnosticCode.invalidTypeId => TypeDiagnosticCode.invalidTypeId,
    wire.DiagnosticCode.invalidRevision => TypeDiagnosticCode.invalidRevision,
    wire.DiagnosticCode.duplicateDefinition =>
      TypeDiagnosticCode.duplicateDefinition,
    wire.DiagnosticCode.invalidArity => TypeDiagnosticCode.genericArity,
    wire.DiagnosticCode.unsatisfiedBound => TypeDiagnosticCode.genericBound,
    wire.DiagnosticCode.invalidVariance => TypeDiagnosticCode.varianceViolation,
    wire.DiagnosticCode.inheritanceCycle => TypeDiagnosticCode.inheritanceCycle,
    wire.DiagnosticCode.inheritanceConflict =>
      TypeDiagnosticCode.conflictingInheritance,
    wire.DiagnosticCode.weakenedConstraint =>
      TypeDiagnosticCode.weakenedConstraint,
    wire.DiagnosticCode.incompatibleRepresentation =>
      TypeDiagnosticCode.incompatibleRepresentation,
    wire.DiagnosticCode.invalidValue => TypeDiagnosticCode.invalidValue,
    wire.DiagnosticCode.missingRequiredField => TypeDiagnosticCode.missingField,
    wire.DiagnosticCode.unknownField => TypeDiagnosticCode.unknownField,
    wire.DiagnosticCode.invalidPath => TypeDiagnosticCode.invalidPath,
    wire.DiagnosticCode.invalidConcreteType =>
      TypeDiagnosticCode.invalidConcreteType,
    wire.DiagnosticCode.conversionNotFound =>
      TypeDiagnosticCode.conversionNotFound,
    wire.DiagnosticCode.conversionAmbiguous =>
      TypeDiagnosticCode.ambiguousConversion,
    wire.DiagnosticCode.conversionFailed => TypeDiagnosticCode.conversionFailed,
    wire.DiagnosticCode.invalidExpression =>
      TypeDiagnosticCode.invalidExpression,
    wire.DiagnosticCode.evaluationBudgetExceeded =>
      TypeDiagnosticCode.evaluationBudgetExceeded,
    wire.DiagnosticCode.invalidPresentation =>
      TypeDiagnosticCode.invalidPresentation,
    wire.DiagnosticCode.mutationConflict => TypeDiagnosticCode.mutationConflict,
    wire.DiagnosticCode.permissionDenied => TypeDiagnosticCode.permissionDenied,
    wire.DiagnosticCode_unknown() => TypeDiagnosticCode.invalidValue,
  };
}
