import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class EditorTarget {
  SelectableIdentifier get targetId;

  EditorDocument get document;

  EditorValue value(DataPath path);

  EditorMutationResult validate(DataPath path, DataValue value);

  Future<TypedMutationResult> commit(EditorCommit commit);
}

abstract class InspectableSelectable<I extends SelectableIdentifier>
    extends Selectable<I>
    implements EditorTarget {
  const InspectableSelectable();

  @override
  SelectableIdentifier get targetId => id;

  ResolvedTypeRef get rootType {
    final type = document.rootType;
    if (type is NamedType) return type.reference;
    throw StateError("Inspectable root type must be nominal");
  }

  TypeCatalog get typeCatalog => document.typeCatalog;

  TypeRegistry get typeRegistry => TypeRegistry(typeCatalog);

  Widget? buildInspectorHeader();

  @override
  EditorValue value(DataPath path) =>
      document.confirmedValue.readEditorValue(path);

  @override
  EditorMutationResult validate(DataPath path, DataValue value) => document
      .rootType
      .validateEditorMutation(path, value, registry: typeRegistry);

  EditorMutationResult validateUpdate(DataPath path, DataValue value) =>
      validate(path, value);
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
