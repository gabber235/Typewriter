import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("Conversion paths", () {
    test(
      "automatic conversion selects the unique cheapest lossless local path",
      () {
        final source = _reference("source");
        final middle = _reference("middle");
        final target = _reference("target");
        final graph = ConversionGraph([
          _conversion("direct", source, target, cost: 5),
          _conversion("first", source, middle),
          _conversion("second", middle, target),
        ]);

        final result = graph.automaticPath(source, target);

        expect(result.valueOrNull!.map((edge) => edge.id.name), [
          "first",
          "second",
        ]);
      },
    );

    test("automatic conversion excludes lossy, fallible, and remote edges", () {
      final source = _reference("source");
      final target = _reference("target");
      final graph = ConversionGraph([
        _conversion("lossy", source, target, safety: ConversionSafety.lossy),
        _conversion("fallible", source, target, fallible: true),
        _conversion(
          "remote",
          source,
          target,
          locality: ConversionLocality.realm,
        ),
      ]);

      final automatic = graph.automaticPath(source, target);
      final explicit = graph.explicitPath(source, target);

      expect(
        automatic.diagnostics.single.code,
        TypeDiagnosticCode.conversionFailed,
      );
      expect(
        explicit.diagnostics.single.code,
        TypeDiagnosticCode.ambiguousConversion,
      );
    });

    test("equally cheap paths are diagnosed as ambiguous", () {
      final source = _reference("source");
      final left = _reference("left");
      final right = _reference("right");
      final target = _reference("target");
      final graph = ConversionGraph([
        _conversion("sourceLeft", source, left),
        _conversion("leftTarget", left, target),
        _conversion("sourceRight", source, right),
        _conversion("rightTarget", right, target),
      ]);

      final result = graph.automaticPath(source, target);

      expect(
        result.diagnostics.single.code,
        TypeDiagnosticCode.ambiguousConversion,
      );
    });

    test("an identity conversion requires no edges", () {
      final reference = _reference("same");

      final result = ConversionGraph([]).automaticPath(reference, reference);

      expect(result.valueOrNull, isEmpty);
    });

    test("inheritance upcasts are zero cost lossless conversions", () {
      final parent = _revision("conversion_parent");
      final child = _revision("conversion_child");
      final registry = TypeRegistry(
        TypeCatalog([
          TypeDefinition(
            id: parent,
            kind: NominalTypeKind.concrete,
            representation: RecordType(fields: {}),
          ),
          TypeDefinition(
            id: child,
            kind: NominalTypeKind.concrete,
            representation: RecordType(fields: {}),
            parents: [parent],
          ),
        ]),
      );
      final source = child;
      final target = parent;

      final graph = ConversionGraph.withInheritance(
        registry: registry,
        applications: [source],
      ).valueOrNull!;
      final path = graph.automaticPath(source, target).valueOrNull!;

      expect(path, hasLength(1));
      expect(path.single.cost, 0);
      expect(path.single.safety, ConversionSafety.lossless);
    });

    test("zero cost cycles do not make path search diverge", () {
      final source = _reference("cycle_source");
      final middle = _reference("cycle_middle");
      final target = _reference("cycle_target");
      final graph = ConversionGraph([
        _conversion("forward", source, middle, cost: 0),
        _conversion("back", middle, source, cost: 0),
        _conversion("target", middle, target),
      ]);

      final path = graph.automaticPath(source, target).valueOrNull!;

      expect(path.map((edge) => edge.id.name), ["forward", "target"]);
    });
  });
}

ResolvedTypeRef _revision(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: name),
  revision: 1,
);

ResolvedTypeRef _reference(String name) => _revision(name);

ConversionDefinition _conversion(
  String id,
  ResolvedTypeRef source,
  ResolvedTypeRef target, {
  ConversionSafety safety = ConversionSafety.lossless,
  bool fallible = false,
  ConversionLocality locality = ConversionLocality.local,
  int cost = 1,
}) => ConversionDefinition(
  id: ConversionId(namespace: "test", name: id),
  source: source,
  target: target,
  rule: const ConversionRule.input(),
  safety: safety,
  fallible: fallible,
  locality: locality,
  cost: cost,
);
