import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Inspector", type: AuthoredResourceEditor)
Widget authoredResourceEditorUseCase(BuildContext context) {
  final fixture = _fixture();
  return FakeApp(
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AuthoredResourceEditor(
          resource: fixture.resource,
          draft: fixture.draft,
          catalog: fixture.catalog,
          role: skir.PresentationRole.inspector,
          budget: skir.EvaluationBudget(
            maxSteps: 1000,
            maxCollectionItems: 1000,
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "New draft", type: AuthoredResourceEditor)
Widget authoredNewDraftUseCase(BuildContext context) =>
    const FakeApp(child: AuthoredNewDraftStory());

final class AuthoredNewDraftStory extends StatefulWidget {
  const AuthoredNewDraftStory({super.key});

  @override
  State<AuthoredNewDraftStory> createState() => _AuthoredNewDraftStoryState();
}

final class _AuthoredNewDraftStoryState extends State<AuthoredNewDraftStory> {
  late final fixture = _fixture(unfilled: true);
  String? outcome;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final selected = await showCreationConcreteTypePicker(
                  context,
                  expected: skir.TypeSelection.createComplete(
                    definition: fixture.page,
                    arguments: const [],
                  ),
                  catalog: fixture.catalog,
                );
                if (selected == null || !mounted) return;
                setState(
                  () => outcome =
                      "Selected ${fixture.catalog.typeSelectionName(selected)}",
                );
              },
              icon: const Icon(Icons.search),
              label: const Text("Search page types"),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AuthoredResourceEditor(
              resource: fixture.resource,
              draft: fixture.draft,
              catalog: fixture.catalog,
              role: skir.PresentationRole.inspector,
              budget: skir.EvaluationBudget(
                maxSteps: 1000,
                maxCollectionItems: 1000,
              ),
            ),
          ),
        ),
        if (outcome case final value?)
          Semantics(liveRegion: true, child: Text(value)),
      ],
    ),
  );
}

({
  skir.ResourceId resource,
  AuthoredDraft draft,
  CheckedEditorCatalog catalog,
  skir.TypeDefinitionId page,
})
_fixture({bool unfilled = false}) {
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
    required bool abstract,
    skir.TypeDisplay? display,
  }) => skir.PublishedType(
    display: display,
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: abstract,
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
    String color,
  ) => skir.TypeDisplay(
    name: name,
    description: description,
    icon: icon,
    color: color,
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
    skir.EditorCatalogWireSnapshot(
      generation: generation,
      types: [
        skir.PublishedType(
          display: null,
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
              abstract_: false,
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
        pageType(page, abstract: true),
        pageType(
          sequence,
          abstract: false,
          display: pageDisplay(
            "Sequence",
            "A linear sequence of entries",
            "material-symbols:account-tree",
            "#2196F3",
          ),
        ),
        pageType(
          staticPage,
          abstract: false,
          display: pageDisplay(
            "Static",
            "A fixed collection of entries",
            "material-symbols:push-pin",
            "#673AB7",
          ),
        ),
        pageType(
          scene,
          abstract: false,
          display: pageDisplay(
            "Scene",
            "A spatial scene of connected entries",
            "material-symbols:movie",
            "#FF9800",
          ),
        ),
        pageType(
          manifest,
          abstract: false,
          display: pageDisplay(
            "Manifest",
            "A manifest of reusable entries",
            "material-symbols:schema",
            "#4CAF50",
          ),
        ),
      ],
      relations: const [],
      resourceDefinitions: const [],
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
              multiline: false,
              placeholder: null,
              inputFormatters: const [],
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
      initialization: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final resource = skir.ResourceId(value: "message:widgetbook");
  final record = skir.AuthoringRecord(
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
    draft: AuthoredDraft(
      generation: generation,
      resources: [
        skir.AuthoringResource(
          id: resource,
          definition: skir.ResourceDefinitionId(value: "widgetbook.message"),
          content: record,
        ),
      ],
      links: const [],
      catalog: checked,
    ),
  );
}
