import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/conversion.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirConversionEncoder {
  const SkirConversionEncoder(this.types, this.paths);

  final SkirTypeCodec types;
  final SkirDataPathCodec paths;

  TypeResult<List<wire.ConversionDefinition>> encode(
    Iterable<ConversionDefinition> values,
  ) {
    final items = <wire.ConversionDefinition>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final encoded = _definition(value);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final item?) items.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(items)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConversionDefinition> _definition(
    ConversionDefinition value,
  ) {
    final id = value.id.encodeWire();
    final source = types.encodeReference(value.source);
    final target = types.encodeReference(value.target);
    final rule = _rule(value.rule);
    final diagnostics = [
      ...id.diagnostics,
      ...source.diagnostics,
      ...target.diagnostics,
      ...rule.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.ConversionDefinition(
              conversionId: id.valueOrNull!,
              source: source.valueOrNull!,
              target: target.valueOrNull!,
              safety: value.safety == ConversionSafety.lossless
                  ? wire.ConversionSafety.lossless
                  : wire.ConversionSafety.lossy,
              fallibility: value.fallible
                  ? wire.ConversionFallibility.fallible
                  : wire.ConversionFallibility.infallible,
              locality: value.locality == ConversionLocality.local
                  ? wire.ConversionLocality.local
                  : wire.ConversionLocality.realm,
              cost: value.cost,
              rule: rule.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConversionRule> _rule(ConversionRule value) =>
      switch (value) {
        InputConversionRule() => const TypeResult.success(
          wire.ConversionRule.identity,
        ),
        InheritanceUpcastRule() => const TypeResult.success(
          wire.ConversionRule.inheritanceUpcast,
        ),
        ValidatedDowncastRule() => const TypeResult.success(
          wire.ConversionRule.validatedDowncast,
        ),
        ScalarConversionRule(:final conversion) => TypeResult.success(
          wire.ConversionRule.wrapScalarCast(conversion._encodeWire),
        ),
        RecordProjectionConversionRule(:final fields) => _projection(fields),
        RecordConstructionConversionRule(:final fields) => _construction(
          fields,
        ),
        CollectionMappingConversionRule(:final elementConversionId) =>
          elementConversionId.encodeWire().mapValue(
            (id) => wire.ConversionRule.createCollectionMapping(
              elementConversionId: id,
            ),
          ),
        ConversionCompositionIdsRule(:final steps) => _composition(steps),
        RealmConversionRule() => TypeResult.success(
          wire.ConversionRule.createRealm(),
        ),
        FieldConversionRule() ||
        RecordConversionRule() ||
        ListConversionRule() ||
        PolymorphicConversionRule() ||
        PolymorphicMatchingConversionRule() ||
        ComposedConversionRule() => invalidWire(
          "Inline conversion rules have no wire identity",
        ),
      };

  TypeResult<wire.ConversionRule> _projection(
    List<ConversionProjectionField> fields,
  ) {
    final items = <wire.RecordProjectionField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final field in fields) {
      final source = paths.encode(field.source);
      final target = paths.encode(field.target);
      final conversion = field.conversionId == null
          ? const TypeResult<wire_type.ConversionId?>.success(null)
          : (field.conversionId!).encodeWire().mapValue((value) => value);
      diagnostics
        ..addAll(source.diagnostics)
        ..addAll(target.diagnostics)
        ..addAll(conversion.diagnostics);
      if (diagnostics.isEmpty) {
        items.add(
          wire.RecordProjectionField(
            source: source.valueOrNull!,
            target: target.valueOrNull!,
            conversionId: conversion.valueOrNull,
          ),
        );
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.ConversionRule.createRecordProjection(fields: items),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConversionRule> _construction(
    List<ConversionConstructionField> fields,
  ) {
    final items = <wire.RecordConstructionField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final field in fields) {
      final source = paths.encode(field.source);
      diagnostics.addAll(source.diagnostics);
      if (source.valueOrNull case final path?) {
        items.add(
          wire.RecordConstructionField(
            targetField: field.targetField,
            source: path,
            conversionId: field.conversionId == null
                ? null
                : (field.conversionId!).encodeWire().valueOrNull,
          ),
        );
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.ConversionRule.createRecordConstruction(fields: items),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.ConversionRule> _composition(List<ConversionId> steps) {
    final values = <TypeResult<wire_type.ConversionId>>[
      for (final step in steps) step.encodeWire(),
    ];
    final diagnostics = <TypeDiagnostic>[
      for (final value in values) ...value.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.ConversionRule.createComposition(
              steps: values.map((item) => item.valueOrNull!),
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on ScalarConversion {
  wire.ScalarCastKind get _encodeWire => switch (this) {
    ScalarConversion.signedWiden => wire.ScalarCastKind.signedWiden,
    ScalarConversion.signedNarrow => wire.ScalarCastKind.signedNarrow,
    ScalarConversion.unsignedWiden => wire.ScalarCastKind.unsignedWiden,
    ScalarConversion.unsignedNarrow => wire.ScalarCastKind.unsignedNarrow,
    ScalarConversion.integerToFloat => wire.ScalarCastKind.integerToFloat,
    ScalarConversion.floatToInteger => wire.ScalarCastKind.floatToInteger,
    ScalarConversion.integerToDecimal ||
    ScalarConversion.floatToDecimal => wire.ScalarCastKind.numericToDecimal,
    ScalarConversion.decimalToInteger ||
    ScalarConversion.decimalToFloat => wire.ScalarCastKind.decimalToNumeric,
    ScalarConversion.timestampToString => wire.ScalarCastKind.timestampToString,
    ScalarConversion.stringToTimestamp => wire.ScalarCastKind.stringToTimestamp,
    ScalarConversion.durationToString => wire.ScalarCastKind.durationToString,
    ScalarConversion.stringToDuration => wire.ScalarCastKind.stringToDuration,
  };
}
