import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "catalog_definition.freezed.dart";

@freezed
abstract class PresentationDefinition with _$PresentationDefinition {
  const factory PresentationDefinition({
    required PresentationId id,
    required TypeExpression target,
    required PresentationNode root,
  }) = _PresentationDefinition;
}

@freezed
sealed class CapabilityDefinition with _$CapabilityDefinition {
  const factory CapabilityDefinition.search({
    required CapabilityId id,
    required ResolvedTypeRef requestType,
    required ResolvedTypeRef resultType,
  }) = SearchCapabilityDefinition;

  const factory CapabilityDefinition.computation({
    required CapabilityId id,
    required ResolvedTypeRef requestType,
    required ResolvedTypeRef resultType,
  }) = ComputationCapabilityDefinition;

  const factory CapabilityDefinition.command({
    required CapabilityId id,
    required ResolvedTypeRef requestType,
  }) = CommandCapabilityDefinition;
}

@freezed
abstract class TypedValueEnvelope with _$TypedValueEnvelope {
  const factory TypedValueEnvelope({
    required ResolvedTypeRef rootType,
    required DataValue rootValue,
  }) = _TypedValueEnvelope;
}
