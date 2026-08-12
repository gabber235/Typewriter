import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("round trips every diagnostic code and all metadata", () {
    final paths = _paths();
    final path = paths.encode(DataPath.root.field("value")).valueOrNull!;
    final codes = <wire.DiagnosticCode>[
      wire.DiagnosticCode.invalidTypeId,
      wire.DiagnosticCode.invalidRevision,
      wire.DiagnosticCode.duplicateDefinition,
      wire.DiagnosticCode.invalidArity,
      wire.DiagnosticCode.unsatisfiedBound,
      wire.DiagnosticCode.invalidVariance,
      wire.DiagnosticCode.inheritanceCycle,
      wire.DiagnosticCode.inheritanceConflict,
      wire.DiagnosticCode.weakenedConstraint,
      wire.DiagnosticCode.incompatibleRepresentation,
      wire.DiagnosticCode.invalidValue,
      wire.DiagnosticCode.missingRequiredField,
      wire.DiagnosticCode.unknownField,
      wire.DiagnosticCode.invalidPath,
      wire.DiagnosticCode.invalidConcreteType,
      wire.DiagnosticCode.conversionNotFound,
      wire.DiagnosticCode.conversionAmbiguous,
      wire.DiagnosticCode.conversionFailed,
      wire.DiagnosticCode.invalidExpression,
      wire.DiagnosticCode.evaluationBudgetExceeded,
      wire.DiagnosticCode.invalidPresentation,
      wire.DiagnosticCode.mutationConflict,
      wire.DiagnosticCode.permissionDenied,
    ];
    final severities = [
      wire.DiagnosticSeverity.information,
      wire.DiagnosticSeverity.warning,
      wire.DiagnosticSeverity.error,
    ];

    for (final entry in codes.indexed) {
      final original = wire.TypeDiagnostic(
        code: entry.$2,
        severity: severities[entry.$1 % severities.length],
        message: "Diagnostic ${entry.$1}",
        path: path,
        relatedType: "example::type@1",
        details: [
          wire.DiagnosticDetail(key: "index", value: "${entry.$1}"),
          wire.DiagnosticDetail(key: "source", value: "test"),
        ],
      );

      final bytes = wire.TypeDiagnostic.serializer.toBytes(original);
      final decodedWire = wire.TypeDiagnostic.serializer.fromBytes(bytes);
      final domain = decodedWire.decodeWire(paths);
      final encoded = domain.encodeWire(paths);

      expect(wire.TypeDiagnostic.serializer.toBytes(encoded), bytes);
    }
  });

  test("preserves an absent diagnostic path", () {
    final paths = _paths();
    final original = wire.TypeDiagnostic(
      code: wire.DiagnosticCode.invalidPresentation,
      severity: wire.DiagnosticSeverity.warning,
      message: "No path",
      path: null,
      relatedType: null,
      details: const [],
    );

    final domain = original.decodeWire(paths);
    final encoded = domain.encodeWire(paths);

    expect(encoded.path, isNull);
    expect(
      wire.TypeDiagnostic.serializer.toBytes(encoded),
      wire.TypeDiagnostic.serializer.toBytes(original),
    );
  });
}

SkirDataPathCodec _paths() {
  final types = SkirTypeCodec(TypeRegistry(TypeCatalog(const [])));
  return SkirDataPathCodec(SkirDataValueCodec(types));
}
