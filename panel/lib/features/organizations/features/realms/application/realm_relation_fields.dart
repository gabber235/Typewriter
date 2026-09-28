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
  Iterable<ResolvedTypeRef> creatableRoots(ResourceDefinitionId definition) sync* {
    final accepted = resourceDefinitions[definition]?.acceptedRoot;
    if (accepted == null) return;
    final registry = TypeRegistry(catalog);
    for (final type in catalog.definitions) {
      if (type.kind == NominalTypeKind.concrete &&
          NamedType(type.id).isStructurallyAssignableTo(accepted, registry)) {
        yield type.id;
      }
    }
  }

  RealmRelationField? relationField(
    ResolvedTypeRef owner,
    DataPath path,
  ) {
    final registry = TypeRegistry(catalog);
    final representation = registry.resolveExact(owner).valueOrNull?.representation;
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
      for (final endpoint in [relation.sourceEndpoint, relation.targetEndpoint]) {
        if (endpoint == null || endpoint.path != path) continue;
        if (!NamedType(owner).isStructurallyAssignableTo(
          NamedType(endpoint.owner),
          registry,
        )) {
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
    final registry = TypeRegistry(catalog);
    for (final type in catalog.definitions) {
      if (type.kind != NominalTypeKind.concrete ||
          !field.accepts(type.id, registry)) {
        continue;
      }
      if (resourceDefinitionFor(type.id) != null) yield type.id;
    }
  }

  RealmResourceDefinition? resourceDefinitionFor(ResolvedTypeRef root) {
    final registry = TypeRegistry(catalog);
    for (final definition in resourceDefinitions.values) {
      if (NamedType(root).isStructurallyAssignableTo(
        definition.acceptedRoot,
        registry,
      )) {
        return definition;
      }
    }
    return null;
  }
}
