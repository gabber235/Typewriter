part of "tag_selectable.dart";

/// Stable nominal type for the editable tag inspector document.
///
/// The representation is the editor boundary, not the wire shape. Identity is
/// supplied by the selected resource, while name, color, direct parents, and
/// graph placement are editable fields.
const tagInspectorTypeRef = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "panel", name: "Tag"),
  revision: 1,
);

const _tagInspectorPresentationId = PresentationId(
  namespace: "panel",
  name: "tag.inspector",
);

final tagInspectorTypeDefinition = TypeDefinition(
  id: tagInspectorTypeRef,
  kind: NominalTypeKind.concrete,
  defaultPresentationId: _tagInspectorPresentationId,
  representation: RecordType(
    fields: {
      "name": TypeField(name: "name", type: identifierStringType),
      "color": TypeField(
        name: "color",
        type: NamedType(standardTypeRefs.color),
      ),
      "parents": TypeField(
        name: "parents",
        type: ListType(
          element: ReferenceType(target: referenceResourceTypes.tag),
          unique: true,
        ),
      ),
      "layout": TypeField(
        name: "layout",
        type: RecordType(
          fields: {
            "x": TypeField(
              name: "x",
              type: IntegerType(width: IntegerWidth.signed32),
            ),
            "y": TypeField(
              name: "y",
              type: IntegerType(width: IntegerWidth.signed32),
            ),
            "width": TypeField(
              name: "width",
              type: IntegerType(width: IntegerWidth.signed32),
            ),
            "height": TypeField(
              name: "height",
              type: IntegerType(width: IntegerWidth.signed32),
            ),
          },
        ),
      ),
    },
  ),
);

final _tagInspectorCatalog = TypeCatalog([
  ...referenceResourceTypes.definitions,
  tagInspectorTypeDefinition,
]);

/// Presentation shared by single and compatible multi tag inspection.
final _tagInspectorPresentation = PresentationDefinition.single(
  id: _tagInspectorPresentationId,
  target: NamedType(tagInspectorTypeRef),
  root: PresentationNode(
    id: "tag.inspector",
    element: ColumnElement(
      spacing: 16,
      crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
      children: [
        PresentationNode(
          id: "tag.name",
          element: TextInputElement(
            control: BoundControl(
              binding: _tagInspectorField("name"),
              label: "Name".asStringLiteral,
            ),
            multiline: false,
            inputFormatters: identifierInputFormats,
          ),
        ),
        PresentationNode(
          id: "tag.color",
          element: ColorInputElement(
            control: BoundControl(
              binding: _tagInspectorField("color"),
              label: "Color".asStringLiteral,
            ),
          ),
        ),
        PresentationNode(
          id: "tag.parents",
          element: ReferenceInputElement(
            control: BoundControl(
              binding: _tagInspectorField("parents"),
              label: "Direct Parents".asStringLiteral,
            ),
            allowReorder: false,
            candidatePolicy: tagParentReferencePolicyId,
            rejectionDisplay: ReferenceRejectionDisplay.disabled,
          ),
        ),
        effectiveTagGraph(
          id: "tag.inheritance",
          title: "Inheritance",
          roots: _tagInspectorField("parents"),
        ),
        _tagLayoutPresentation,
      ],
    ),
  ),
);

final _tagLayoutPresentation = PresentationNode(
  id: "tag.layout",
  header: PresentationHeader(
    title: "Layout".asStringLiteral.asHeaderTitle,
    initiallyExpanded: false,
  ),
  element: SectionElement(
    child: PresentationNode(
      id: "tag.layout.fields",
      element: GridElement(
        columns: 2,
        horizontalSpacing: 12,
        verticalSpacing: 12,
        children: [
          for (final field in ["x", "y", "width", "height"])
            PresentationNode(
              id: "tag.layout.$field",
              element: NumericInputElement(
                BoundControl(
                  binding: BindingReference(
                    bindingId: const BindingId(0),
                    path: DataPath.root.field("layout").field(field),
                  ),
                  label: switch (field) {
                    "x" || "y" => null,
                    "width" => "Width".asStringLiteral,
                    _ => "Height".asStringLiteral,
                  },
                  prefix: switch (field) {
                    "x" || "y" => PresentationNode(
                      id: "tag.layout.$field.prefix",
                      element: TextElement(field.toUpperCase().asStringLiteral),
                    ),
                    _ => null,
                  },
                  semanticLabel: switch (field) {
                    "x" => "X position".asStringLiteral,
                    "y" => "Y position".asStringLiteral,
                    _ => null,
                  },
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);

/// Builds one inspector for multiple tags without merging their identities.
///
/// Common field edits are delegated to the shared multi editor. The collection
/// is available only when all selected tags expose the same keys and stable row
/// values. Selectability is intersected, preventing a parent link that is safe
/// for one selected tag but invalid for another.
final class TagMultiInspectionDefinition implements MultiInspectionDefinition {
  const TagMultiInspectionDefinition();

  @override
  PresentationId get id => _tagInspectorPresentationId;

  @override
  bool isCompatibleWith(MultiInspectionDefinition other) =>
      other is TagMultiInspectionDefinition;

  @override
  TypeResult<InspectionContent> build(
    List<EditableSelectable> selection,
    InspectionBuildContext context,
  ) {
    final selected = selection.requireAll<TagSelectable>();
    final tags = selected.valueOrNull;
    if (tags == null) return TypeResult.failure(selected.diagnostics);
    final catalog = tags.mergedTypeCatalog;
    final merged = catalog.valueOrNull;
    if (merged == null) return TypeResult.failure(catalog.diagnostics);
    final collection = tags.sharedTagCollection;
    final shared = collection.valueOrNull;
    if (shared == null) return TypeResult.failure(collection.diagnostics);
    final owner = context.multiEditorFor(
      tags,
      rootType: const NamedType(tagInspectorTypeRef),
      typeCatalog: merged,
    );
    return TypeResult.success(
      InspectionContent(
        model: PresentationModel.editor(
          owner: owner,
          presentations: [_tagInspectorPresentation],
          collections: [shared],
        ),
      ),
    );
  }
}

/// Derives a collection safe for a shared multi tag editor.
extension TagSelectionCollectionIntersection on List<TagSelectable> {
  TypeResult<PresentationCollectionSource> get sharedTagCollection {
    final sources = map((selection) => selection.tagCollection).toList();
    if (sources.isEmpty ||
        sources.any((source) => source is! LocalPresentationCollectionSource)) {
      return _inconsistentTagCollection();
    }
    final local = sources.cast<LocalPresentationCollectionSource>();
    final first = local.first;
    if (local.any(
      (source) => source.id != first.id || source.schema != first.schema,
    )) {
      return _inconsistentTagCollection();
    }
    final indexed = local.map((source) => source.rows._indexTagRows()).toList();
    if (indexed.any((rows) => rows == null)) {
      return _inconsistentTagCollection();
    }
    final rows = indexed.cast<Map<DataValue, RecordValue>>();
    final keys = rows.first.keys.toSet();
    if (rows
        .skip(1)
        .any(
          (candidate) => !const SetEquality<DataValue>().equals(
            keys,
            candidate.keys.toSet(),
          ),
        )) {
      return _inconsistentTagCollection();
    }

    final combined = <DataValue>[];
    for (final key in rows.first.keys) {
      final candidates = rows.map((values) => values[key]!).toList();
      final stableFields = candidates.first.fields.withoutSelectable;
      if (candidates
          .skip(1)
          .any(
            (candidate) => !const MapEquality<String, DataValue>().equals(
              stableFields,
              candidate.fields.withoutSelectable,
            ),
          )) {
        return _inconsistentTagCollection();
      }
      final selectable = candidates.every(
        (candidate) =>
            candidate.fields["selectable"] == const BooleanValue(true),
      );
      combined.add(
        RecordValue({...stableFields, "selectable": BooleanValue(selectable)}),
      );
    }
    return TypeResult.success(
      LocalPresentationCollectionSource(
        id: first.id,
        schema: first.schema,
        rows: combined,
        registry: first.registry,
        searchPredicate: first.searchPredicate,
        expressionBudget: first.expressionBudget,
        graphNodeBudget: first.graphNodeBudget,
      ),
    );
  }
}

extension on Iterable<DataValue> {
  Map<DataValue, RecordValue>? _indexTagRows() {
    final indexed = <DataValue, RecordValue>{};
    for (final value in this) {
      if (value is! RecordValue) return null;
      final key = value.fields["key"];
      if (key == null || indexed.containsKey(key)) return null;
      indexed[key] = value;
    }
    return indexed;
  }
}

extension on Map<String, DataValue> {
  Map<String, DataValue> get withoutSelectable => {
    for (final entry in entries)
      if (entry.key != "selectable") entry.key: entry.value,
  };
}

TypeResult<PresentationCollectionSource> _inconsistentTagCollection() =>
    TypeResult.failure([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Selected Tags have inconsistent collection snapshots",
      ),
    ]);

BindingReference _tagInspectorField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);
