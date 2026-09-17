import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final types = SkirTypeCodec(TypeRegistry(TypeCatalog(const [])));
  final values = SkirDataValueCodec(types);
  final paths = SkirDataPathCodec(values);
  final encoder = SkirConversionEncoder(types, paths);
  final decoder = SkirConversionCodec(types, paths);
  final source = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "source"),
    revision: 1,
  );

  final target = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "example", name: "target"),
    revision: 2,
  );

  test("maps every conversion rule variant and definition field", () {
    final rules = <ConversionRule>[
      const InputConversionRule(),
      const InheritanceUpcastRule(),
      const ValidatedDowncastRule(),
      for (final conversion in ScalarConversion.values)
        ScalarConversionRule(conversion),
      const RecordProjectionConversionRule([
        ConversionProjectionField(
          source: DataPath.root,
          target: DataPath.root,
          conversionId: ConversionId(namespace: "example", name: "field"),
        ),
      ]),
      const RecordConstructionConversionRule([
        ConversionConstructionField(
          targetField: "name",
          source: DataPath.root,
          conversionId: ConversionId(namespace: "example", name: "field"),
        ),
      ]),
      const CollectionMappingConversionRule(
        ConversionId(namespace: "example", name: "element"),
      ),
      const ConversionCompositionIdsRule([
        ConversionId(namespace: "example", name: "first"),
        ConversionId(namespace: "example", name: "second"),
      ]),
      const RealmConversionRule(),
    ];

    for (final entry in rules.indexed) {
      final definition = ConversionDefinition(
        id: ConversionId(namespace: "example", name: "conversion_${entry.$1}"),
        source: source,
        target: target,
        rule: entry.$2,
        safety: entry.$1.isEven
            ? ConversionSafety.lossless
            : ConversionSafety.lossy,
        fallible: entry.$1.isOdd,
        locality: entry.$2 is RealmConversionRule
            ? ConversionLocality.realm
            : ConversionLocality.local,
        cost: entry.$1,
      );
      final encoded = encoder.encode([definition]).valueOrNull!.single;

      expect(encoded.conversionId.namespace, "example");
      expect(encoded.conversionId.name, "conversion_${entry.$1}");
      expect(encoded.source, types.encodeReference(source).valueOrNull);
      expect(encoded.target, types.encodeReference(target).valueOrNull);
      expect(encoded.rule.kind, _wireKind(entry.$2));
      expect(encoded.cost, entry.$1);

      expect(
        encoded.safety.kind,
        entry.$1.isEven
            ? skir.ConversionSafety_kind.losslessConst
            : skir.ConversionSafety_kind.lossyConst,
      );
      expect(
        encoded.fallibility.kind,
        entry.$1.isOdd
            ? skir.ConversionFallibility_kind.fallibleConst
            : skir.ConversionFallibility_kind.infallibleConst,
      );
      expect(
        encoded.locality.kind,
        entry.$2 is RealmConversionRule
            ? skir.ConversionLocality_kind.realmConst
            : skir.ConversionLocality_kind.localConst,
      );
      expect(
        decoder.decode([encoded]).valueOrNull!.single,
        definition.copyWith(rule: _canonicalRule(entry.$2)),
      );
    }
  });
}

skir.ConversionRule_kind _wireKind(ConversionRule rule) => switch (rule) {
  InputConversionRule() => skir.ConversionRule_kind.identityConst,
  InheritanceUpcastRule() => skir.ConversionRule_kind.inheritanceUpcastConst,
  ValidatedDowncastRule() => skir.ConversionRule_kind.validatedDowncastConst,
  ScalarConversionRule() => skir.ConversionRule_kind.scalarCastWrapper,
  RecordProjectionConversionRule() =>
    skir.ConversionRule_kind.recordProjectionWrapper,
  RecordConstructionConversionRule() =>
    skir.ConversionRule_kind.recordConstructionWrapper,
  CollectionMappingConversionRule() =>
    skir.ConversionRule_kind.collectionMappingWrapper,
  ConversionCompositionIdsRule() => skir.ConversionRule_kind.compositionWrapper,
  RealmConversionRule() => skir.ConversionRule_kind.realmWrapper,
  _ => throw StateError("Unsupported conversion rule in mapping test"),
};

ConversionRule _canonicalRule(ConversionRule rule) => switch (rule) {
  ScalarConversionRule(conversion: ScalarConversion.floatToDecimal) =>
    const ScalarConversionRule(ScalarConversion.integerToDecimal),
  ScalarConversionRule(conversion: ScalarConversion.decimalToInteger) =>
    const ScalarConversionRule(ScalarConversion.decimalToFloat),
  _ => rule,
};
