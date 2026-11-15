import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A trusted local catalog of [types] alone, for a panel owned editor that
/// declares no presentations, relations, capabilities or operations.
///
/// [generation] names the catalog so its snapshots are told apart from a
/// realm's.
CheckedEditorCatalog trustedLocalTypeCatalog({
  required String generation,
  required List<skir.PublishedType> types,
}) => skir.EditorCatalog(
  resourceDisplays: const [],
  resourceOperations: const [],
  generation: skir.CatalogGeneration(value: generation),
  types: types,
  presentations: const [],
  presentationMaterials: const [],
  configuration: const [],
  capabilities: const [],
  relations: const [],
  endpointBindings: const [],
  realmRoot: skir.TypeDefinitionId.defaultInstance,
  recommendations: const [],
  roleFallbacks: const [],
  diagnostics: const [],
).asTrustedLocalCatalog();

/// Installs a local catalog asset whose types were made effective by its owner.
///
/// This boundary validates identity and reference integrity only. It does not
/// resolve inheritance, substitute generic arguments, collect declarations,
/// or derive effective fields. Callers must supply the same final wire shape
/// that a checked catalog snapshot would contain.
extension TrustedLocalEditorCatalog on skir.EditorCatalog {
  CheckedEditorCatalog asTrustedLocalCatalog() {
    final typesById = <skir.TypeDefinitionId, skir.PublishedType>{};
    for (final published in types) {
      final id = published.definition.id;
      if (typesById.containsKey(id)) {
        throw ArgumentError.value(id, "snapshot", "Duplicate published type");
      }
      typesById[id] = published;
      final fieldNames = <String>{};
      for (final field in published.effectiveFields) {
        if (!fieldNames.add(field.key)) {
          throw ArgumentError.value(
            field.key,
            "snapshot",
            "Duplicate effective field",
          );
        }
        if (field.owner.definition != id &&
            !types.any(
              (candidate) => candidate.definition.id == field.owner.definition,
            )) {
          throw ArgumentError.value(
            field.owner,
            "snapshot",
            "Effective field owner is absent",
          );
        }
      }
    }

    final presentationIds = <skir.PresentationId>{};
    for (final descriptor in presentations) {
      if (!presentationIds.add(descriptor.id)) {
        throw ArgumentError.value(
          descriptor.id,
          "snapshot",
          "Duplicate presentation descriptor",
        );
      }
    }
    for (final material in presentationMaterials) {
      if (!presentationIds.contains(material.provider)) {
        throw ArgumentError.value(
          material.provider,
          "snapshot",
          "Presentation material provider is absent",
        );
      }
    }
    return CheckedEditorCatalog(this);
  }
}
