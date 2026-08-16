part of "tag_selectable.dart";

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
      "name": TypeField(name: "name", type: StringType(minimumLength: 1)),
      "color": TypeField(
        name: "color",
        type: NamedType(standardTypeRefs.color),
      ),
      "parents": TypeField(
        name: "parents",
        type: ListType(
          element: NamedType(
            standardTypeRefs.refTo(NamedType(tagInspectorTypeRef)),
          ),
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

final _tagInspectorCatalog = TypeCatalog([tagInspectorTypeDefinition]);

final _tagInspectorPresentation = PresentationDefinition(
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
        tagReferenceSearch(
          id: "tag.parents",
          label: "Direct Parents",
          binding: _tagInspectorField("parents"),
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

BindingReference _tagInspectorField(String name) => BindingReference(
  bindingId: const BindingId(0),
  path: DataPath.root.field(name),
);
