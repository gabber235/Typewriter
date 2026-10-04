import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as type_catalog;
import "package:typewriter_panel/typewriter_panel.dart"
    show CheckedEditorCatalog;

/// Installs a local catalog asset whose types were made effective by its owner.
///
/// This boundary validates identity and reference integrity only. It does not
/// resolve inheritance, substitute generic arguments, collect declarations,
/// or derive effective fields. Callers must supply the same final wire shape
/// that a checked catalog snapshot would contain.
extension TrustedLocalEditorCatalog on catalog.EditorCatalogWireSnapshot {
  CheckedEditorCatalog asTrustedLocalCatalog() {
    final typesById = <type_catalog.TypeDefinitionId, catalog.PublishedType>{};
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

    final presentationIds = <type_catalog.PresentationId>{};
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
