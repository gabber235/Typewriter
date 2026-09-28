// Translates catalog presentations, capabilities, and typed envelopes.
//
// These definitions are the panel's executable description of realm editor
// behavior. The adapter resolves referenced types before the presentation or
// capability reaches application code, so an invalid catalog cannot create a
// partially usable editor.
import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as wire_capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as wire_presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/typed_value.dart"
    as wire_value;
import "package:typewriter_panel/typewriter_panel.dart";

/// Encodes and decodes definitions that depend on the editor catalog.
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

  /// Decodes a presentation and validates its declared input bindings.
  TypeResult<PresentationDefinition> decodePresentation(
    wire_presentation.PresentationDefinition value,
  ) {
    final id = _decodeQualified(
      value.presentationId.namespace,
      value.presentationId.name,
    );
    final inputs = <PresentationInputParameter>[];
    final diagnostics = [...id.diagnostics];
    for (final input in value.inputs) {
      final type = types.decodeExpression(input.valueType);
      diagnostics.addAll(type.diagnostics);
      final access = switch (input.access) {
        wire_presentation.PresentationInputAccess.read =>
          PresentationInputAccess.read,
        wire_presentation.PresentationInputAccess.edit =>
          PresentationInputAccess.edit,
        _ => null,
      };
      if (access == null ||
          input.name.isEmpty ||
          input.bindingId.value < 0 ||
          inputs.any(
            (existing) =>
                existing.id.value == input.bindingId.value ||
                existing.name == input.name,
          )) {
        return invalidWire("Invalid or duplicate presentation input");
      }
      if (type.valueOrNull case final type?) {
        inputs.add(
          PresentationInputParameter(
            id: BindingId(input.bindingId.value),
            name: input.name,
            type: type,
            access: access,
          ),
        );
      }
    }
    if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
    final primary = value.primaryInput;

    if (primary != null &&
        !inputs.any((input) => input.id.value == primary.value)) {
      return invalidWire("Primary presentation input is not declared");
    }
    final collections = _decodeCollections(value.dependencies.collections);
    if (collections case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      PresentationDefinition(
        id: PresentationId(
          namespace: id.valueOrNull!.$1,
          name: id.valueOrNull!.$2,
        ),
        inputs: inputs,
        primaryInput: primary == null ? null : BindingId(primary.value),
        root: presentations.decodeNode(value.root),
        collections: collections.valueOrNull!,
      ),
    );
  }

  /// Encodes a domain presentation and its executable root node.
  TypeResult<wire_presentation.PresentationDefinition> encodePresentation(
    PresentationDefinition value,
  ) {
    final inputs = <wire_presentation.PresentationInput>[];
    for (final input in value.inputs) {
      final type = types.encodeExpression(input.type);
      if (type case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      inputs.add(
        wire_presentation.PresentationInput(
          bindingId: wire_binding.BindingId(value: input.id.value),
          name: input.name,
          valueType: type.valueOrNull!,
          access: switch (input.access) {
            PresentationInputAccess.read =>
              wire_presentation.PresentationInputAccess.read,
            PresentationInputAccess.edit =>
              wire_presentation.PresentationInputAccess.edit,
          },
        ),
      );
    }
    final collections = _encodeCollections(value.collections);
    if (collections case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return presentationEncoder
        .encodeNode(value.root)
        .mapValue(
          (root) => wire_presentation.PresentationDefinition(
            presentationId: wire_type.PresentationId(
              namespace: value.id.namespace,
              name: value.id.name,
            ),
            inputs: inputs,
            primaryInput: value.primaryInput == null
                ? null
                : wire_binding.BindingId(value: value.primaryInput!.value),
            root: root,
            dependencies: wire_presentation.PresentationDependencies(
              types: const [],
              presentations: const [],
              conversions: const [],
              capabilities: const [],
              collections: collections.valueOrNull!,
            ),
          ),
        );
  }

  TypeResult<Map<PresentationCollectionSourceId, PresentationCollectionSchema>>
  _decodeCollections(
    Iterable<wire_presentation.PresentationCollectionDefinition> values,
  ) {
    final collections =
        <PresentationCollectionSourceId, PresentationCollectionSchema>{};
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      if (value.sourceId.isEmpty || value.rowBindingId.value < 0) {
        diagnostics.addAll(
          invalidWire<void>("Invalid presentation collection identity")
              .diagnostics,
        );
        continue;
      }
      final sourceId = PresentationCollectionSourceId(value.sourceId);
      if (collections.containsKey(sourceId)) {
        diagnostics.addAll(
          invalidWire<void>("Duplicate presentation collection source")
              .diagnostics,
        );
        continue;
      }
      final rowType = types.decodeExpression(value.rowType);
      final key = presentations.expressions.decode(value.key);
      final selectability = presentations.expressions.decode(
        value.selectability,
      );
      diagnostics
        ..addAll(rowType.diagnostics)
        ..addAll(key.diagnostics)
        ..addAll(selectability.diagnostics);
      final relations = <PresentationCollectionRelation>[];
      final relationIds = <PresentationCollectionRelationId>{};
      for (final relation in value.relations) {
        if (relation.relationId.isEmpty) {
          diagnostics.addAll(
            invalidWire<void>("Invalid presentation collection relation")
                .diagnostics,
          );
          continue;
        }
        final id = PresentationCollectionRelationId(relation.relationId);
        if (!relationIds.add(id)) {
          diagnostics.addAll(
            invalidWire<void>("Duplicate presentation collection relation")
                .diagnostics,
          );
          continue;
        }
        final targets = presentations.expressions.decode(relation.targets);
        diagnostics.addAll(targets.diagnostics);
        if (targets.valueOrNull case final expression?) {
          relations.add(
            PresentationCollectionRelation(id: id, targets: expression),
          );
        }
      }
      if (selectability.valueOrNull?.resultType is! BooleanType) {
        diagnostics.addAll(
          invalidWire<void>(
            "Presentation collection selectability must be boolean",
          ).diagnostics,
        );
      }
      if (rowType.valueOrNull case final decodedRowType?) {
        if (key.valueOrNull case final decodedKey?) {
          if (selectability.valueOrNull case final decodedSelectability?) {
            collections[sourceId] = PresentationCollectionSchema(
              rowType: decodedRowType,
              rowBindingId: BindingId(value.rowBindingId.value),
              key: decodedKey,
              selectability: decodedSelectability,
              relations: relations,
            );
          }
        }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(Map.unmodifiable(collections))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<List<wire_presentation.PresentationCollectionDefinition>>
  _encodeCollections(
    Map<PresentationCollectionSourceId, PresentationCollectionSchema> values,
  ) {
    final collections = <wire_presentation.PresentationCollectionDefinition>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final entry in values.entries) {
      final rowType = types.encodeExpression(entry.value.rowType);
      final key = presentationEncoder.expressions.encode(entry.value.key);
      final selectability = presentationEncoder.expressions.encode(
        entry.value.selectability,
      );
      diagnostics
        ..addAll(rowType.diagnostics)
        ..addAll(key.diagnostics)
        ..addAll(selectability.diagnostics);
      final relations =
          <wire_presentation.PresentationCollectionRelationDefinition>[];
      for (final relation in entry.value.relations) {
        final targets = presentationEncoder.expressions.encode(
          relation.targets,
        );
        diagnostics.addAll(targets.diagnostics);
        if (targets.valueOrNull case final expression?) {
          relations.add(
            wire_presentation.PresentationCollectionRelationDefinition(
              relationId: relation.id.value,
              targets: expression,
            ),
          );
        }
      }
      final encodedRowType = rowType.valueOrNull;
      final encodedKey = key.valueOrNull;
      final encodedSelectability = selectability.valueOrNull;
      if (encodedRowType == null ||
          encodedKey == null ||
          encodedSelectability == null) {
        continue;
      }
      collections.add(
        wire_presentation.PresentationCollectionDefinition(
          sourceId: entry.key.value,
          rowType: encodedRowType,
          rowBindingId: wire_binding.BindingId(
            value: entry.value.rowBindingId.value,
          ),
          key: encodedKey,
          selectability: encodedSelectability,
          relations: relations,
        ),
      );
    }
    return diagnostics.isEmpty
        ? TypeResult.success(collections)
        : TypeResult.failure(diagnostics);
  }

  /// Decodes a capability after resolving its request and result types.
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

  /// Decodes a value together with the type that gives it meaning.
  TypeResult<TypedValueEnvelope> decodeEnvelope(
    wire_value.TypedValueEnvelope value,
  ) => combineResults(
    types.decodeReference(value.rootType),
    values.decode(value.rootValue),
    (type, value) => TypedValueEnvelope(rootType: type, rootValue: value),
  );

  /// Encodes a typed value envelope for capability transport.
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
