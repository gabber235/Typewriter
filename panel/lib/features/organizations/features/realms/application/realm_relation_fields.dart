import "package:typewriter_panel/typewriter_panel.dart";

final class RealmRelationField {
  const RealmRelationField({
    required this.relation,
    required this.endpoint,
    required this.target,
  });

  final RealmRelationDefinition relation;
  final RealmRelationEndpointDefinition endpoint;
  final ResolvedTypeRef target;

  bool accepts(ResolvedTypeRef root, TypeRegistry registry) =>
      NamedType(root).isStructurallyAssignableTo(NamedType(target), registry);
}

extension RealmRelationFields on RealmEditorCatalogSnapshot {
  Iterable<RealmTypeEntry> creatableTypes({
    ResourceDefinitionId? definition,
    RealmRelationField? field,
  }) sync* {
    final registry = TypeRegistry(catalog);
    for (final type in types.values) {
      if (!type.eligible || type.definition.kind != NominalTypeKind.concrete) {
        continue;
      }
      final resource = resourceDefinitionFor(type.type);
      if (resource == null ||
          definition != null && resource.id != definition ||
          field != null && !field.accepts(type.type, registry)) {
        continue;
      }
      yield type;
    }
  }

  Iterable<ResolvedTypeRef> creatableRoots(
    ResourceDefinitionId definition,
  ) sync* {
    for (final type in creatableTypes(definition: definition)) {
      yield type.type;
    }
  }

  RealmRelationField? relationField(ResolvedTypeRef owner, DataPath path) {
    final registry = TypeRegistry(catalog);
    final representation = registry
        .resolveExact(owner)
        .valueOrNull
        ?.representation;
    if (representation is! RecordType || path.segments.length != 1) {
      return null;
    }
    final segment = path.segments.single;
    if (segment is! FieldPathSegment) return null;
    final field = representation.fields[segment.name];
    if (field == null) return null;
    final target = switch (field.type) {
      ReferenceType(:final target) => target,
      ListType(element: ReferenceType(:final target)) => target,
      _ => null,
    };
    if (target == null) return null;
    for (final relation in relations.values) {
      for (final endpoint in [
        relation.sourceEndpoint,
        relation.targetEndpoint,
      ]) {
        if (endpoint == null || endpoint.path != path) continue;
        if (!NamedType(owner)
            .isStructurallyAssignableTo(NamedType(endpoint.owner), registry)) {
          continue;
        }
        return RealmRelationField(
          relation: relation,
          endpoint: endpoint,
          target: target,
        );
      }
    }
    return null;
  }

  Iterable<ResolvedTypeRef> creatableTargets(RealmRelationField field) sync* {
    for (final type in creatableTypes(field: field)) {
      yield type.type;
    }
  }

  RealmResourceDefinition? resourceDefinitionFor(ResolvedTypeRef root) {
    final registry = TypeRegistry(catalog);
    for (final definition in resourceDefinitions.values) {
      if (NamedType(root)
          .isStructurallyAssignableTo(definition.acceptedRoot, registry)) {
        return definition;
      }
    }
    return null;
  }
}
