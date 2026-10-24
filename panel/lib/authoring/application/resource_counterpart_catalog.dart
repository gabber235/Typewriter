part of "realm_edit_model.dart";

/// Whether canonical relation metadata identifies one direct scalar counterpart.
@freezed
sealed class ResourceCounterpartResolution
    with _$ResourceCounterpartResolution {
  const factory ResourceCounterpartResolution.resolved(
    skir.ValueLocation location,
  ) = ResolvedResourceCounterpart;
  const factory ResourceCounterpartResolution.choiceRequired(String message) =
      ResourceCounterpartChoiceRequired;
  const factory ResourceCounterpartResolution.invalid(String message) =
      InvalidResourceCounterpart;
}

extension ResourceCounterpartCatalog on CheckedEditorCatalog {
  ResourceCounterpartResolution resolveScalarCounterpart({
    required skir.TypeSelection configuration,
    required skir.ResourceId resource,
    required skir.EndpointId endpoint,
  }) {
    if (selected(configuration)?.status != skir.DeclarationStatus.ready) {
      return const ResourceCounterpartResolution.invalid(
        "The counterpart resource type is unavailable",
      );
    }
    if (!snapshot.relations.any(
      (relation) =>
          relation.first.id == endpoint || relation.second.id == endpoint,
    )) {
      return const ResourceCounterpartResolution.invalid(
        "The counterpart relation endpoint is unavailable",
      );
    }
    final bindings = endpointBindings(configuration)
        .where((binding) => binding.template.endpoint == endpoint)
        .toList();
    if (bindings.isEmpty) {
      return const ResourceCounterpartResolution.invalid(
        "The resource has no binding for the counterpart endpoint",
      );
    }
    final owners = nominalDefinitions(configuration);
    final candidates = <skir.ValueLocation>{};
    for (final binding in bindings) {
      if (binding.template.containsCollection ||
          !owners.contains(binding.template.valueOwner)) {
        continue;
      }
      final path = _directFieldPath(binding.template.relativePath);
      if (path != null && path.segments.length == 1) {
        candidates.add(skir.ValueLocation(resource: resource, path: path));
      }
    }
    if (candidates.length == 1) {
      return ResourceCounterpartResolution.resolved(candidates.single);
    }
    return ResourceCounterpartResolution.choiceRequired(
      candidates.isEmpty
          ? "The counterpart is nested or belongs to a collection. Choose its location explicitly"
          : "More than one counterpart location is available. Choose one explicitly",
    );
  }
}
