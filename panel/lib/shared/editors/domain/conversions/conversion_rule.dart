import "package:typewriter_panel/typewriter_panel.dart";

part "conversion_rule.freezed.dart";

/// Declarative value transformation used by a [ConversionDefinition].
///
/// Inline rules compose local operations. Rules containing conversion IDs or
/// paths are catalog references and require graph context before execution.
/// [ConversionRuleEvaluation] handles only the self contained subset.
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

/// Scalar transformations understood by the local evaluator.
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

/// Maps one concrete polymorphic source variant to a target variant.
///
/// The nested rule transforms the variant payload. Matching is by the exact
/// source type reference, and the result is re tagged with [targetType].
@freezed
abstract class ConversionPolymorphicCase with _$ConversionPolymorphicCase {
  const factory ConversionPolymorphicCase({
    required ResolvedTypeRef sourceType,
    required ResolvedTypeRef targetType,
    required ConversionRule rule,
  }) = _ConversionPolymorphicCase;
}

/// Maps one source data path to one target data path.
///
/// [conversionId] optionally names the graph conversion applied between the
/// paths. The evaluator does not execute this reference without graph context.
@freezed
abstract class ConversionProjectionField with _$ConversionProjectionField {
  const factory ConversionProjectionField({
    required DataPath source,
    required DataPath target,
    ConversionId? conversionId,
  }) = _ConversionProjectionField;
}

/// Supplies one field while constructing a target record.
///
/// [source] identifies the input path and [targetField] identifies the output
/// field. [conversionId] names an optional conversion for the field value.
@freezed
abstract class ConversionConstructionField with _$ConversionConstructionField {
  const factory ConversionConstructionField({
    required String targetField,
    required DataPath source,
    ConversionId? conversionId,
  }) = _ConversionConstructionField;
}

/// Describes a graph backed mapping between polymorphic concrete types.
///
/// The optional [conversionId] identifies the payload conversion. This model
/// is metadata only; matching and execution require the conversion graph.
@freezed
abstract class ConversionPolymorphicMatch with _$ConversionPolymorphicMatch {
  const factory ConversionPolymorphicMatch({
    required ResolvedTypeRef sourceType,
    required ResolvedTypeRef targetType,
    ConversionId? conversionId,
  }) = _ConversionPolymorphicMatch;
}
