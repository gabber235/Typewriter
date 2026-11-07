import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(name: "Inspector", type: AuthoredResourceEditor)
Widget authoredResourceEditorUseCase(BuildContext context) {
  final title = context.knobs.object.segmented(
    label: "Title",
    options: const ["Filled", "Unfinished"],
    initialOption: "Filled",
  );
  final message = messageFixture(unfilled: title == "Unfinished");
  return Story(
    [
      signedIn(ada, organization: acme),
      realmServing(message.draft.toDocument()),
      ...context.knobs.traits("Saves", {
        "Confirmed": const [],
        "Held by the Realm": const [heldSaves],
      }),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: 520,
        child: RealmEditingScene(
          builder: (context, workspace, commands) => AuthoredResourceInspection(
            resource: message.resource,
            workspace: workspace,
            commands: commands,
            commitPolicy: EditorCommitPolicy.applyResource,
          ),
        ),
      ),
    ),
  );
}

/// A Realm of one quest message with a text title, typed by a catalog that
/// also declares four concrete page types below an open Page.
({
  skir.ResourceId resource,
  AuthoringEdit draft,
  CheckedEditorCatalog catalog,
  skir.TypeDefinitionId page,
})
messageFixture({bool unfilled = false}) {
  final generation = skir.CatalogGeneration(value: "catalog:widgetbook");
  final definition = skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "widgetbook", name: "Message"),
    ),
    revision: 1,
  );
  skir.TypeDefinitionId pageDefinition(String name) => skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "widgetbook", name: name),
    ),
    revision: 1,
  );
  final page = pageDefinition("Page");
  final sequence = pageDefinition("SequencePage");
  final staticPage = pageDefinition("StaticPage");
  final scene = pageDefinition("ScenePage");
  final manifest = pageDefinition("ManifestPage");
  final pageParent = skir.NamedTypeTemplate(
    definition: page,
    arguments: const [],
  );
  skir.PublishedType pageType(
    skir.TypeDefinitionId id, {
    required bool open,
    skir.TypeDisplay? display,
  }) => skir.PublishedType(
    name: "",
    searchKey: null,
    placementField: null,
    display: display ?? defaultTypeDisplay(""),
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        form: open ? skir.RecordForm.open : skir.RecordForm.concrete,
      ),
      parents: id == page ? const [] : [pageParent],
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: id == page ? const [] : [pageParent],
  );
  skir.TypeDisplay pageDisplay(
    String name,
    String description,
    String icon,
    int argb,
  ) => skir.TypeDisplay(
    name: name,
    description: description,
    icon: skir.Icon.wrapIconify(icon),
    color: skir.Color(argb: argb.toSigned(32)),
  );
  final presentationId = skir.PresentationId(
    namespace: "widgetbook",
    name: "message.inspector",
  );
  final target = skir.PresentationTarget.createNamed(
    definition: definition,
    arguments: const [],
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
      generation: generation,
      types: [
        skir.PublishedType(
          name: "",
          searchKey: null,
          placementField: null,
          display: defaultTypeDisplay(""),
          definition: skir.TypeDefinition(
            id: definition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(definition: definition, name: "title"),
                  type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              form: skir.RecordForm.concrete,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "title",
              owner: skir.FieldOwner(definition: definition, name: "title"),
              type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
        pageType(page, open: true),
        pageType(
          sequence,
          open: false,
          display: pageDisplay(
            "Sequence",
            "A linear sequence of entries",
            "material-symbols:account-tree",
            0xff2196f3,
          ),
        ),
        pageType(
          staticPage,
          open: false,
          display: pageDisplay(
            "Static",
            "A fixed collection of entries",
            "material-symbols:push-pin",
            0xff673ab7,
          ),
        ),
        pageType(
          scene,
          open: false,
          display: pageDisplay(
            "Scene",
            "A spatial scene of connected entries",
            "material-symbols:movie",
            0xffff9800,
          ),
        ),
        pageType(
          manifest,
          open: false,
          display: pageDisplay(
            "Manifest",
            "A manifest of reusable entries",
            "material-symbols:schema",
            0xff4caf50,
          ),
        ),
      ],
      relations: const [],
      realmRoot: skir.TypeDefinitionId.defaultInstance,
      presentations: [
        skir.PresentationDescriptor(
          id: presentationId,
          owner: skir.DeclarationOwner.defaultInstance,
          target: target,
          roles: [skir.PresentationRole.inspector],
          priority: 0,
        ),
      ],
      presentationMaterials: [
        skir.PresentationMaterial(
          inheritableNodes: const [],

          provider: presentationId,
          target: target,
          role: skir.PresentationRole.inspector,
          layout: skir.PresentationNode(
            nodeId: "message.title",
            properties: skir.PresentationProperties.defaultInstance,
            element: skir.PresentationElement.createTextInput(
              control: skir.BoundControl(
                binding: skir.BindingRef(
                  bindingId: configuredValueBindingId,
                  path: skir.ValuePath(
                    segments: [skir.PathSegment.createField(name: "title")],
                  ),
                ),
                label: skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapStringValue("Title"),
                ),
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              appearance: null,
              content: null,
              entry: null,
              mappings: null,
              options: skir.TextEditingOptions.defaultInstance,
            ),
            header: null,
          ),
          dependencies: skir.PresentationDependencies.defaultInstance,
          subject: skir.TypeTemplate.createNamed(
            definition: definition,
            arguments: const [],
          ),
        ),
      ],
      configuration: const [],
      diagnostics: const [],

      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = skir.ResourceId(value: "message:widgetbook");
  final record = skir.AuthoringRecord(
    types: const [],
    configuration: skir.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    ),
    fields: [
      skir.FieldValue(
        name: "title",
        value: unfilled
            ? skir.DataValue.unfilled
            : skir.DataValue.wrapStringValue("Quest objective"),
      ),
    ],
  );
  return (
    resource: resource,
    page: page,
    catalog: checked,
    draft: AuthoringEdit(
      generation: generation,
      resources: [skir.AuthoringResource(id: resource, content: record)],
      links: const [],
      catalog: checked,
    ),
  );
}
