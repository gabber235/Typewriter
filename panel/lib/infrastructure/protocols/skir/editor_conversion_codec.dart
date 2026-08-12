import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/conversion.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirConversionCodec {
  const SkirConversionCodec(this.types, this.paths);

  final SkirTypeCodec types;
  final SkirDataPathCodec paths;

  TypeResult<List<ConversionDefinition>> decode(
    Iterable<wire.ConversionDefinition> value,
  ) {
    final conversions = <ConversionDefinition>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final item in value) {
      final decoded = _definition(item);
      diagnostics.addAll(decoded.diagnostics);
      if (decoded.valueOrNull case final conversion?) {
        conversions.add(conversion);
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(conversions)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConversionDefinition> _definition(
    wire.ConversionDefinition value,
  ) {
    final id = value.conversionId.decodeDomain();
    final source = types.decodeReference(value.source);
    final target = types.decodeReference(value.target);
    final rule = _rule(value.rule);
    final diagnostics = [
      ...id.diagnostics,
      ...source.diagnostics,
      ...target.diagnostics,
      ...rule.diagnostics,
    ];
    final safety = switch (value.safety) {
      wire.ConversionSafety.lossless => ConversionSafety.lossless,
      wire.ConversionSafety.lossy => ConversionSafety.lossy,
      _ => null,
    };
    final fallible = switch (value.fallibility) {
      wire.ConversionFallibility.infallible => false,
      wire.ConversionFallibility.fallible => true,
      _ => null,
    };
    final locality = switch (value.locality) {
      wire.ConversionLocality.local => ConversionLocality.local,
      wire.ConversionLocality.realm => ConversionLocality.realm,
      _ => null,
    };
    if (safety == null ||
        fallible == null ||
        locality == null ||
        value.cost < 0) {
      diagnostics.add(wireDiagnostic("Conversion metadata is invalid"));
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final decodedRule = rule.valueOrNull!;
    return TypeResult.success(
      ConversionDefinition(
        id: id.valueOrNull!,
        source: source.valueOrNull!,
        target: target.valueOrNull!,
        rule: decodedRule,
        safety: safety!,
        fallible: fallible!,
        locality: locality!,
        cost: value.cost,
      ),
    );
  }

  TypeResult<ConversionRule> _rule(wire.ConversionRule value) =>
      switch (value) {
        wire.ConversionRule.identity => const TypeResult.success(
          InputConversionRule(),
        ),
        wire.ConversionRule.inheritanceUpcast => const TypeResult.success(
          InheritanceUpcastRule(),
        ),
        wire.ConversionRule.validatedDowncast => const TypeResult.success(
          ValidatedDowncastRule(),
        ),
        wire.ConversionRule_scalarCastWrapper(:final value) =>
          value._decodeDomain().mapValue(ScalarConversionRule.new),
        wire.ConversionRule_recordProjectionWrapper(:final value) =>
          _projection(value),
        wire.ConversionRule_recordConstructionWrapper(:final value) =>
          _construction(value),
        wire.ConversionRule_collectionMappingWrapper(:final value) =>
          value.elementConversionId.decodeDomain().mapValue(
            CollectionMappingConversionRule.new,
          ),
        wire.ConversionRule_compositionWrapper(:final value) => _composition(
          value,
        ),
        wire.ConversionRule_realmWrapper() => const TypeResult.success(
          RealmConversionRule(),
        ),
        wire.ConversionRule_unknown() => invalidWire("Unknown conversion rule"),
      };
}

extension on wire.ScalarCastKind {
  TypeResult<ScalarConversion> _decodeDomain() {
    final decoded = switch (this) {
      wire.ScalarCastKind.signedWiden => ScalarConversion.signedWiden,
      wire.ScalarCastKind.signedNarrow => ScalarConversion.signedNarrow,
      wire.ScalarCastKind.unsignedWiden => ScalarConversion.unsignedWiden,
      wire.ScalarCastKind.unsignedNarrow => ScalarConversion.unsignedNarrow,
      wire.ScalarCastKind.integerToFloat => ScalarConversion.integerToFloat,
      wire.ScalarCastKind.floatToInteger => ScalarConversion.floatToInteger,
      wire.ScalarCastKind.numericToDecimal => ScalarConversion.integerToDecimal,
      wire.ScalarCastKind.decimalToNumeric => ScalarConversion.decimalToFloat,
      wire.ScalarCastKind.timestampToString =>
        ScalarConversion.timestampToString,
      wire.ScalarCastKind.stringToTimestamp =>
        ScalarConversion.stringToTimestamp,
      wire.ScalarCastKind.durationToString => ScalarConversion.durationToString,
      wire.ScalarCastKind.stringToDuration => ScalarConversion.stringToDuration,
      _ => null,
    };
    return decoded == null
        ? invalidWire("Unknown scalar conversion")
        : TypeResult.success(decoded);
  }
}

extension SkirConversionCodecRules on SkirConversionCodec {
  TypeResult<ConversionRule> _projection(wire.RecordProjectionRule value) {
    final fields = <ConversionProjectionField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final field in value.fields) {
      final source = paths.decode(field.source);
      final target = paths.decode(field.target);
      diagnostics
        ..addAll(source.diagnostics)
        ..addAll(target.diagnostics);
      final conversion = field.conversionId == null
          ? const TypeResult<ConversionId?>.success(null)
          : (field.conversionId!).decodeDomain().mapValue((value) => value);
      diagnostics.addAll(conversion.diagnostics);
      if (source.valueOrNull case final decodedSource?) {
        if (target.valueOrNull case final decodedTarget?) {
          fields.add(
            ConversionProjectionField(
              source: decodedSource,
              target: decodedTarget,
              conversionId: conversion.valueOrNull,
            ),
          );
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(RecordProjectionConversionRule(fields))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConversionRule> _construction(wire.RecordConstructionRule value) {
    final fields = <ConversionConstructionField>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final field in value.fields) {
      final source = paths.decode(field.source);
      diagnostics.addAll(source.diagnostics);
      if (field.targetField.isEmpty) {
        diagnostics.add(wireDiagnostic("Target field is empty"));
      }
      final conversion = field.conversionId == null
          ? const TypeResult<ConversionId?>.success(null)
          : (field.conversionId!).decodeDomain().mapValue((value) => value);
      diagnostics.addAll(conversion.diagnostics);
      if (source.valueOrNull case final decoded?
          when field.targetField.isNotEmpty) {
        fields.add(
          ConversionConstructionField(
            targetField: field.targetField,
            source: decoded,
            conversionId: conversion.valueOrNull,
          ),
        );
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(RecordConstructionConversionRule(fields))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<ConversionRule> _composition(
    wire.ConversionCompositionRule value,
  ) {
    final steps = value.steps.map((id) => id.decodeDomain()).toList();
    final diagnostics = steps.expand((step) => step.diagnostics).toList();
    return diagnostics.isEmpty
        ? TypeResult.success(
            ConversionCompositionIdsRule(
              steps.map((step) => step.valueOrNull!).toList(),
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension WireConversionIdDecoding on wire_type.ConversionId {
  TypeResult<ConversionId> decodeDomain() => namespace.isEmpty || name.isEmpty
      ? invalidWire("Conversion id is empty")
      : TypeResult.success(ConversionId(namespace: namespace, name: name));
}

extension ConversionIdWireEncoding on ConversionId {
  TypeResult<wire_type.ConversionId> encodeWire() => TypeResult.success(
    wire_type.ConversionId(namespace: namespace, name: name),
  );
}
