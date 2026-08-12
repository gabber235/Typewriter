import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as wire_catalog;
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
      ),
    );
  }

  TypeResult<RealmActionDefinition> decodeRealmAction(
    wire_catalog.RealmActionDefinition value,
  ) {
    final id = _decodeQualified(
      value.realmActionId.namespace,
      value.realmActionId.name,
    );
    final payload = types.decodeReference(value.payloadType);
    final result = value.resultType == null
        ? const TypeResult<ResolvedTypeRef?>.success(null)
        : types.decodeReference(value.resultType).mapValue((value) => value);
    final diagnostics = [
      ...id.diagnostics,
      ...payload.diagnostics,
      ...result.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            RealmActionDefinition(
              id: RealmActionId(
                namespace: id.valueOrNull!.$1,
                name: id.valueOrNull!.$2,
              ),
              payloadType: payload.valueOrNull!,
              resultType: result.valueOrNull,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire_catalog.RealmActionDefinition> encodeRealmAction(
    RealmActionDefinition value,
  ) {
    final payload = types.encodeReference(value.payloadType);
    final result = value.resultType == null
        ? const TypeResult<wire_type.ResolvedTypeRef?>.success(null)
        : types.encodeReference(value.resultType!).mapValue((value) => value);
    return combineResults(
      payload,
      result,
      (payload, result) => wire_catalog.RealmActionDefinition(
        realmActionId: wire_type.RealmActionId(
          namespace: value.id.namespace,
          name: value.id.name,
        ),
        payloadType: payload,
        resultType: result,
      ),
    );
  }

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
