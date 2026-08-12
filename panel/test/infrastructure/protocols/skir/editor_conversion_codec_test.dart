import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/conversion.dart"
    as wire;
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

  test("round trips every conversion rule variant as bytes", () {
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
      final bytes = wire.ConversionDefinition.serializer.toBytes(encoded);
      final decodedWire = wire.ConversionDefinition.serializer.fromBytes(bytes);
      final decoded = decoder.decode([decodedWire]).valueOrNull!.single;
      final reencoded = encoder.encode([decoded]).valueOrNull!.single;
      expect(wire.ConversionDefinition.serializer.toBytes(reencoded), bytes);
    }
  });
}
