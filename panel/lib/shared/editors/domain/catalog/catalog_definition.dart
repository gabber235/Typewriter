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
abstract class RealmActionDefinition with _$RealmActionDefinition {
  const factory RealmActionDefinition({
    required RealmActionId id,
    required ResolvedTypeRef payloadType,
    ResolvedTypeRef? resultType,
  }) = _RealmActionDefinition;
}

@freezed
abstract class TypedValueEnvelope with _$TypedValueEnvelope {
  const factory TypedValueEnvelope({
    required ResolvedTypeRef rootType,
    required DataValue rootValue,
  }) = _TypedValueEnvelope;
}
