import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("maps every diagnostic code and all metadata", () {
    final paths = _paths();
    final path = paths.encode(DataPath.root.field("value")).valueOrNull!;

    final codes = <skir.DiagnosticCode>[
      skir.DiagnosticCode.invalidTypeId,
      skir.DiagnosticCode.invalidRevision,
      skir.DiagnosticCode.duplicateDefinition,
      skir.DiagnosticCode.invalidArity,
      skir.DiagnosticCode.unsatisfiedBound,
      skir.DiagnosticCode.invalidVariance,
      skir.DiagnosticCode.inheritanceCycle,
      skir.DiagnosticCode.inheritanceConflict,
      skir.DiagnosticCode.weakenedConstraint,
      skir.DiagnosticCode.incompatibleRepresentation,
      skir.DiagnosticCode.invalidValue,
      skir.DiagnosticCode.missingRequiredField,
      skir.DiagnosticCode.unknownField,
      skir.DiagnosticCode.invalidPath,
      skir.DiagnosticCode.invalidConcreteType,
      skir.DiagnosticCode.conversionNotFound,
      skir.DiagnosticCode.conversionAmbiguous,
      skir.DiagnosticCode.conversionFailed,
      skir.DiagnosticCode.invalidExpression,
      skir.DiagnosticCode.evaluationBudgetExceeded,
      skir.DiagnosticCode.invalidPresentation,
      skir.DiagnosticCode.mutationConflict,
      skir.DiagnosticCode.permissionDenied,
    ];

    final severities = [
      skir.DiagnosticSeverity.information,
      skir.DiagnosticSeverity.warning,
      skir.DiagnosticSeverity.error,
    ];

    final domainCodes = [
      TypeDiagnosticCode.invalidTypeId,
      TypeDiagnosticCode.invalidRevision,
      TypeDiagnosticCode.duplicateDefinition,
      TypeDiagnosticCode.genericArity,
      TypeDiagnosticCode.genericBound,
      TypeDiagnosticCode.varianceViolation,
      TypeDiagnosticCode.inheritanceCycle,
      TypeDiagnosticCode.conflictingInheritance,
      TypeDiagnosticCode.weakenedConstraint,
      TypeDiagnosticCode.incompatibleRepresentation,
      TypeDiagnosticCode.invalidValue,
      TypeDiagnosticCode.missingField,
      TypeDiagnosticCode.unknownField,
      TypeDiagnosticCode.invalidPath,
      TypeDiagnosticCode.invalidConcreteType,
      TypeDiagnosticCode.conversionNotFound,
      TypeDiagnosticCode.ambiguousConversion,
      TypeDiagnosticCode.conversionFailed,
      TypeDiagnosticCode.invalidExpression,
      TypeDiagnosticCode.evaluationBudgetExceeded,
      TypeDiagnosticCode.invalidPresentation,
      TypeDiagnosticCode.mutationConflict,
      TypeDiagnosticCode.permissionDenied,
    ];

    final domainSeverities = TypeDiagnosticSeverity.values;

    for (final entry in codes.indexed) {
      final original = skir.TypeDiagnostic(
        code: entry.$2,
        severity: severities[entry.$1 % severities.length],
        message: "Diagnostic ${entry.$1}",
        path: path,
        relatedType: "example::type@1",
        details: [
          skir.DiagnosticDetail(key: "index", value: "${entry.$1}"),
          skir.DiagnosticDetail(key: "source", value: "test"),
        ],
      );

      final domain = original.decodeWire(paths);
      final encoded = domain.encodeWire(paths);

      expect(domain.code, domainCodes[entry.$1]);
      expect(domain.severity, domainSeverities[entry.$1 % 3]);
      expect(domain.message, "Diagnostic ${entry.$1}");
      expect(domain.path, DataPath.root.field("value"));
      expect(domain.relatedType, "example::type@1");
      expect(domain.details, [
        TypeDiagnosticDetail(key: "index", value: "${entry.$1}"),
        const TypeDiagnosticDetail(key: "source", value: "test"),
      ]);

      expect(encoded.code, original.code);
      expect(encoded.severity, original.severity);
      expect(encoded.message, original.message);
      expect(encoded.path, original.path);
      expect(encoded.relatedType, original.relatedType);
      expect(encoded.details, original.details);
    }
  });

  test("preserves an absent diagnostic path", () {
    final paths = _paths();
    final original = skir.TypeDiagnostic(
      code: skir.DiagnosticCode.invalidPresentation,
      severity: skir.DiagnosticSeverity.warning,
      message: "No path",
      path: null,
      relatedType: null,
      details: const [],
    );

    final domain = original.decodeWire(paths);
    final encoded = domain.encodeWire(paths);

    expect(encoded.path, isNull);
    expect(
      skir.TypeDiagnostic.serializer.toBytes(encoded),
      skir.TypeDiagnostic.serializer.toBytes(original),
    );
  });
}

SkirDataPathCodec _paths() {
  final types = SkirTypeCodec(TypeRegistry(TypeCatalog(const [])));
  return SkirDataPathCodec(SkirDataValueCodec(types));
}
