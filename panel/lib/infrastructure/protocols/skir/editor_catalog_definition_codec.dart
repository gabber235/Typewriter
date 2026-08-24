import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as wire_capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire_presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/typed_value.dart"
    as wire_value;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirCatalogDefinitionCodec {
  const SkirCatalogDefinitionCodec({
    required this.types,
    required this.values,
    required this.presentations,
    required this.presentationEncoder,
  });

  final SkirTypeCodec types;
  final SkirDataValueCodec values;
  final SkirPresentationDecoder presentations;
  final SkirPresentationEncoder presentationEncoder;

  TypeResult<PresentationDefinition> decodePresentation(
    wire_presentation.PresentationDefinition value,
  ) {
    final id = _decodeQualified(
      value.presentationId.namespace,
      value.presentationId.name,
    );
    final target = types.decodeExpression(value.target);
    return combineResults(
      id,
      target,
      (id, target) => PresentationDefinition(
        id: PresentationId(namespace: id.$1, name: id.$2),
        target: target,
        root: presentations.decodeNode(value.root),
      ),
    );
  }

  TypeResult<wire_presentation.PresentationDefinition> encodePresentation(
    PresentationDefinition value,
  ) {
    final target = types.encodeExpression(value.target);
    final root = presentationEncoder.encodeNode(value.root);
    return combineResults(
      target,
      root,
      (target, root) => wire_presentation.PresentationDefinition(
        presentationId: wire_type.PresentationId(
          namespace: value.id.namespace,
          name: value.id.name,
        ),
        target: target,
        root: root,
        dependencies: wire_presentation.PresentationDependencies(
          types: const [],
          presentations: const [],
          conversions: const [],
          capabilities: const [],
        ),
      ),
    );
  }

  TypeResult<CapabilityDefinition> decodeCapability(
    wire_capability.CapabilityDefinition value,
  ) => switch (value) {
    wire_capability.CapabilityDefinition_searchWrapper(:final value) =>
      _decodeCapabilityTypes(
        value.capabilityId.value,
        value.requestType,
        value.resultType,
        CapabilityDefinition.search,
      ),
    wire_capability.CapabilityDefinition_computationWrapper(:final value) =>
      _decodeCapabilityTypes(
        value.capabilityId.value,
        value.requestType,
        value.resultType,
        CapabilityDefinition.computation,
      ),
    wire_capability.CapabilityDefinition_commandWrapper(:final value) =>
      types
          .decodeReference(value.requestType)
          .mapValue(
            (requestType) => CapabilityDefinition.command(
              id: CapabilityId(value.capabilityId.value),
              requestType: requestType,
            ),
          ),
    wire_capability.CapabilityDefinition_unknown() => invalidWire(
      "Unknown capability definition",
    ),
  };

  TypeResult<CapabilityDefinition> _decodeCapabilityTypes(
    String id,
    wire_type.ResolvedTypeRef request,
    wire_type.ResolvedTypeRef result,
    CapabilityDefinition Function({
      required CapabilityId id,
      required ResolvedTypeRef requestType,
      required ResolvedTypeRef resultType,
    })
    create,
  ) => combineResults(
    types.decodeReference(request),
    types.decodeReference(result),
    (requestType, resultType) => create(
      id: CapabilityId(id),
      requestType: requestType,
      resultType: resultType,
    ),
  );

  TypeResult<TypedValueEnvelope> decodeEnvelope(
    wire_value.TypedValueEnvelope value,
  ) => combineResults(
    types.decodeReference(value.rootType),
    values.decode(value.rootValue),
    (type, value) => TypedValueEnvelope(rootType: type, rootValue: value),
  );

  TypeResult<wire_value.TypedValueEnvelope> encodeEnvelope(
    TypedValueEnvelope value,
  ) => combineResults(
    types.encodeReference(value.rootType),
    values.encode(value.rootValue),
    (type, value) =>
        wire_value.TypedValueEnvelope(rootType: type, rootValue: value),
  );
}

TypeResult<(String, String)> _decodeQualified(String namespace, String name) {
  return namespace.isNotEmpty && name.isNotEmpty
      ? TypeResult.success((namespace, name))
      : invalidWire("Qualified id is invalid");
}
