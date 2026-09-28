import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "catalog_definition.freezed.dart";

/// Describes the inputs and root presentation tree used to edit one value.
///
/// The catalog owns this declarative definition. Presentation renderers own
/// widget state while evaluating the tree against the supplied input bindings.
/// [primaryInput] identifies the input represented by [target], when the
/// presentation has one canonical value. Definitions with several inputs may
/// leave it null and use the input descriptors directly.
@freezed
abstract class PresentationDefinition with _$PresentationDefinition {
  const factory PresentationDefinition({
    required PresentationId id,
    required List<PresentationInputParameter> inputs,
    required PresentationNode root,
    BindingId? primaryInput,
    @Default(<PresentationCollectionSourceId, PresentationCollectionSchema>{})
    Map<PresentationCollectionSourceId, PresentationCollectionSchema>
    collections,
  }) = _PresentationDefinition;

  const PresentationDefinition._();

  /// Creates the common single value form with binding zero as its value.
  ///
  /// The generated root still receives the caller supplied [root], so this
  /// helper establishes the binding contract without imposing a renderer.
  factory PresentationDefinition.single({
    required PresentationId id,
    required TypeExpression target,
    required PresentationNode root,
  }) => PresentationDefinition(
    id: id,
    inputs: [
      PresentationInputParameter(
        id: const BindingId(0),
        name: "value",
        type: target,
      ),
    ],
    primaryInput: const BindingId(0),
    root: root,
  );

  /// Returns the type of the presentation's canonical input, if declared.
  ///
  /// A multi input definition can intentionally have no primary input, so
  /// callers must handle null rather than treating the first input as target.
  TypeExpression? get target =>
      inputs.where((input) => input.id == primaryInput).firstOrNull?.type;
}

/// Controls whether a presentation input is observed or may be edited.
enum PresentationInputAccess {
  /// The renderer may read this input but must not use it as an edit target.
  read,

  /// The input participates in editing and can be written by controls.
  edit,
}

/// Declares one binding available to a [PresentationDefinition] tree.
///
/// Binding identity is explicit because a presentation can combine several
/// values. [access] communicates intent to the editor lifecycle, while [type]
/// tells validation and renderers how to interpret the bound value.
@freezed
abstract class PresentationInputParameter with _$PresentationInputParameter {
  const factory PresentationInputParameter({
    required BindingId id,
    required String name,
    required TypeExpression type,
    @Default(PresentationInputAccess.read) PresentationInputAccess access,
  }) = _PresentationInputParameter;
}

/// Describes an operation the editor can expose through a catalog.
///
/// The request and result types are part of the capability contract. Search and
/// computation produce a result, while command is effect oriented and only
/// declares its request payload. Providers execute these capabilities; this
/// value only advertises their typed boundary.
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

/// Carries a value together with the catalog type used to interpret it.
///
/// Keeping type and value together preserves the contract at renderer and
/// capability boundaries. The envelope is descriptive and does not validate or
/// mutate the contained value.
@freezed
abstract class TypedValueEnvelope with _$TypedValueEnvelope {
  const factory TypedValueEnvelope({
    required ResolvedTypeRef rootType,
    required DataValue rootValue,
  }) = _TypedValueEnvelope;
}
