import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Real SDK declarations and linked records shared by visual and widget checks.
final class CompiledSearchFixture {
  CompiledSearchFixture() {
    final base = CheckedEditorCatalog(compiledSdkControlCatalog);
    final pageRoot = _contract(base, "com.typewritermc.library.Page");
    final elementRoot = _contract(base, "com.typewritermc.elements.Element");
    final pageType = _subtype(
      base.published(pageRoot)!,
      "DialoguePage",
      "Dialogue page",
      0xff607d8b,
    );
    final elementType = _subtype(
      base.published(elementRoot)!,
      "Speaker",
      "Speaker",
      0xff9c64bd,
    );
    final catalog = CheckedEditorCatalog(
      (compiledSdkControlCatalog.toMutable()
            ..types = [
              ...compiledSdkControlCatalog.types,
              pageType,
              elementType,
            ])
          .toFrozen(),
    );
    final empty = AuthoringDocument(
      catalog: catalog,
      entries: const {},
      links: const [],
    );
    skir.AuthoringRecord record(
      skir.TypeDefinitionId type,
      Map<String, skir.DataValue> values,
    ) {
      final selection = skir.TypeSelection.createComplete(
        definition: type,
        arguments: const [],
      );
      return skir.AuthoringRecord(
        configuration: selection,
        fields: [
          for (final field in catalog.fields(selection))
            skir.FieldValue(
              name: field.template.key,
              value:
                  values[field.template.key] ?? empty.defaultValue(field.type),
            ),
        ],
      );
    }

    skir.AuthoringRecord rename(
      skir.AuthoringRecord source,
      String name,
      String label,
    ) => skir.AuthoringRecord(
      configuration: source.configuration,
      fields: [
        for (final field in source.fields)
          if (field.name == name)
            skir.FieldValue(
              name: name,
              value: skir.DataValue.wrapStringValue(label),
            )
          else
            field,
      ],
    );
    final pageSelection = skir.TypeSelection.createComplete(
      definition: pageType.definition.id,
      arguments: const [],
    );
    final chapterType =
        catalog
                .fields(pageSelection)
                .singleWhere((field) => field.template.key == "chapter")
                .type!
            as skir.TypeUse_namedWrapper;
    final records = {
      "book": rename(compiledSdkBookRecord, "title", labels["book"]!),
      "tag": rename(compiledSdkTagRecord, "name", "Quest tag"),
      "page": record(pageType.definition.id, {
        "name": skir.DataValue.wrapStringValue(labels["page"]!),
        "chapter": skir.DataValue.createNamed(
          actualType: chapterType.value,
          payload: skir.DataValue.wrapStringValue("Village"),
        ),
      }),
      "element": record(elementType.definition.id, {
        "name": skir.DataValue.wrapStringValue(labels["element"]!),
        "placement": compiledSdkPlacementValue,
      }),
    };
    final roots = {
      "book":
          (compiledSdkBookRecord.configuration
                  as skir.TypeSelection_completeWrapper)
              .value
              .definition,
      "tag":
          (compiledSdkTagRecord.configuration
                  as skir.TypeSelection_completeWrapper)
              .value
              .definition,
      "page": pageRoot,
      "element": elementRoot,
    };
    final edit = AuthoringEdit(
      generation: catalog.snapshot.generation,
      catalog: catalog,
      resources: [
        for (final entry in records.entries)
          skir.AuthoringResource(
            id: ids[entry.key]!,
            content: entry.value,
            definition: catalog.snapshot.resourceDefinitions
                .singleWhere((resource) => resource.root == roots[entry.key])
                .id,
          ),
      ],
      links: const [],
    );
    void connect(
      String source,
      String field,
      String target, {
      bool multiple = false,
    }) {
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: field),
          if (multiple)
            skir.PathSegment.createItem(id: skir.ItemId(value: target)),
        ],
      );
      final endpoint = catalog
          .endpointBindingsAt(edit.resources[ids[source]]!.configuration, path)
          .single
          .template
          .endpoint;
      edit.connect(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: endpoint,
            location: skir.ValueLocation(resource: ids[source]!, path: path),
          ),
          source: ids[source]!,
          target: skir.LinkTarget(resource: ids[target]!, opposite: null),
        ),
        ids[target]!,
      );
    }

    connect("book", "tags", "tag", multiple: true);
    connect("page", "book", "book");
    connect("element", "page", "page");
    document = edit.toDocument();
  }

  final ids = {
    for (final kind in ["book", "tag", "page", "element"])
      kind: skir.ResourceId(value: "rich:$kind"),
  };
  final labels = {
    "book": "Main Quest",
    "tag": "Quest tag",
    "page": "Meet the Mayor",
    "element": "Mayor greeting",
  };
  late final AuthoringDocument document;
}

skir.TypeDefinitionId _contract(CheckedEditorCatalog catalog, String name) =>
    catalog.snapshot.types
        .singleWhere(
          (type) =>
              type.definition.id.typeId ==
              skir.TypeId.createQualified(namespace: "kotlin", name: name),
        )
        .definition
        .id;

skir.PublishedType _subtype(
  skir.PublishedType base,
  String name,
  String label,
  int argb,
) =>
    (base.toMutable()
          ..definition = skir.TypeDefinition(
            id: skir.TypeDefinitionId(
              typeId: skir.TypeId.createQualified(
                namespace: "rich.fixture",
                name: name,
              ),
              revision: 1,
            ),
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: const [],
              abstract_: false,
            ),
            parents: [
              skir.NamedTypeTemplate(
                definition: base.definition.id,
                arguments: const [],
              ),
            ],
          )
          ..ancestorTemplates = [
            skir.NamedTypeTemplate(
              definition: base.definition.id,
              arguments: const [],
            ),
          ]
          ..display = skir.TypeDisplay(
            name: label,
            description: "Compiled result fixture",
            icon: skir.Icon.wrapIconify("material-symbols:book"),
            color: skir.Color(argb: argb.toSigned(32)),
          ))
        .toFrozen();
