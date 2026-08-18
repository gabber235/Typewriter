import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_rule.freezed.dart";

@freezed
sealed class ConversionRule with _$ConversionRule {
  const factory ConversionRule.input() = InputConversionRule;
  const factory ConversionRule.inheritanceUpcast() = InheritanceUpcastRule;
  const factory ConversionRule.validatedDowncast() = ValidatedDowncastRule;
  const factory ConversionRule.scalar(ScalarConversion conversion) =
      ScalarConversionRule;
  @Assert("name != \"\"", "Field name must not be empty.")
  const factory ConversionRule.field({
    required String name,
    required ConversionRule rule,
  }) = FieldConversionRule;
  const factory ConversionRule.record(Map<String, ConversionRule> fields) =
      RecordConversionRule;
  const factory ConversionRule.list(ConversionRule element) =
      ListConversionRule;
  const factory ConversionRule.polymorphic(
    List<ConversionPolymorphicCase> cases,
  ) = PolymorphicConversionRule;
  const factory ConversionRule.compose(List<ConversionRule> rules) =
      ComposedConversionRule;
  const factory ConversionRule.realm() = RealmConversionRule;
  const factory ConversionRule.recordProjection(
    List<ConversionProjectionField> fields,
  ) = RecordProjectionConversionRule;
  const factory ConversionRule.recordConstruction(
    List<ConversionConstructionField> fields,
  ) = RecordConstructionConversionRule;
  const factory ConversionRule.collectionMapping(
    ConversionId elementConversionId,
  ) = CollectionMappingConversionRule;
  const factory ConversionRule.polymorphicMatching(
    List<ConversionPolymorphicMatch> cases,
  ) = PolymorphicMatchingConversionRule;
  const factory ConversionRule.compositionIds(List<ConversionId> steps) =
      ConversionCompositionIdsRule;
}

enum ScalarConversion {
  signedWiden,
  signedNarrow,
  unsignedWiden,
  unsignedNarrow,
  integerToFloat,
  integerToDecimal,
  floatToInteger,
  floatToDecimal,
  decimalToInteger,
  decimalToFloat,
  timestampToString,
  stringToTimestamp,
  durationToString,
  stringToDuration,
}

@freezed
abstract class ConversionPolymorphicCase with _$ConversionPolymorphicCase {
  const factory ConversionPolymorphicCase({
    required ResolvedTypeRef sourceType,
    required ResolvedTypeRef targetType,
    required ConversionRule rule,
  }) = _ConversionPolymorphicCase;
}

@freezed
abstract class ConversionProjectionField with _$ConversionProjectionField {
  const factory ConversionProjectionField({
    required DataPath source,
    required DataPath target,
    ConversionId? conversionId,
  }) = _ConversionProjectionField;
}

@freezed
abstract class ConversionConstructionField with _$ConversionConstructionField {
  const factory ConversionConstructionField({
    required String targetField,
    required DataPath source,
    ConversionId? conversionId,
  }) = _ConversionConstructionField;
}

@freezed
abstract class ConversionPolymorphicMatch with _$ConversionPolymorphicMatch {
  const factory ConversionPolymorphicMatch({
    required ResolvedTypeRef sourceType,
    required ResolvedTypeRef targetType,
    ConversionId? conversionId,
  }) = _ConversionPolymorphicMatch;
}
