import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract class InspectableSelectable<I extends SelectableIdentifier>
    extends Selectable<I> {
  const InspectableSelectable();

  ResolvedTypeRef get rootType;

  TypeCatalog get typeCatalog;

  TypeRegistry get typeRegistry => TypeRegistry(typeCatalog);

  Widget? buildInspectorHeader();

  EditorValue value(DataPath path);

  EditorMutationResult validateUpdate(DataPath path, DataValue value) =>
      NamedType(
        rootType,
      ).validateEditorMutation(path, value, registry: typeRegistry);

  EditorMutationResult update(DataPath path, DataValue value);
}

extension InspectableSelectableCatalogMerge on Iterable<InspectableSelectable> {
  TypeCatalog get mergedTypeCatalog {
    final definitions = <TypeDefinition>[];
    final firstById = <ResolvedTypeRef, TypeDefinition>{};
    for (final selectable in this) {
      for (final definition in selectable.typeCatalog.definitions) {
        final existing = firstById[definition.id];
        if (identical(existing, definition)) continue;
        firstById.putIfAbsent(definition.id, () => definition);
        definitions.add(definition);
      }
    }
    return TypeCatalog(definitions);
  }
}

extension InspectableSelectableTypeQueries on InspectableSelectable {
  TypeResult<List<TypeReferenceLocation>> referenceLocations({
    String? relation,
  }) {
    final resolved = typeRegistry.resolveExact(rootType);
    final type = resolved.valueOrNull;
    if (type == null) return TypeResult.failure(resolved.diagnostics);
    return TypeResult.success(
      type.representation.queryReferences(relation: relation),
    );
  }
}
