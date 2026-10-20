import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

/// Realm answers the story preview can return for a requested selection.
enum TypePreviewOutcome { ready, rejected }

@widgetbook.UseCase(
  name: "Reward type arguments",
  type: AuthoredTypeArgumentEditor,
)
Widget authoredTypeArgumentEditorUseCase(BuildContext context) =>
    AuthoredTypeArgumentEditorStory(
      twoArguments: context.knobs.boolean(
        label: "Second argument",
        initialValue: false,
      ),
      chosen: context.knobs.boolean(
        label: "First argument chosen",
        initialValue: false,
      ),
      outcome: context.knobs.object.dropdown(
        label: "Preview outcome",
        options: TypePreviewOutcome.values,
        initialOption: TypePreviewOutcome.ready,
        labelBuilder: (outcome) => outcome.name,
      ),
      enabled: context.knobs.boolean(label: "Enabled", initialValue: true),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 480,
        min: 320,
        max: 720,
      ),
    );

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "typewriter", name: name),
  revision: 1,
);

final _variable = _definition("RewardVariable");
final _reward = _definition("Reward");
final _coins = _definition("CoinReward");
final _items = _definition("ItemReward");
final _experience = _definition("ExperienceReward");
final _resource = skir.ResourceId(value: "variable:quest_reward");

CheckedEditorCatalog _catalog({required bool twoArguments}) {
  final rewardParent = skir.NamedTypeTemplate(
    definition: _reward,
    arguments: const [],
  );
  skir.PublishedType published(
    skir.TypeDefinitionId id, {
    required String name,
    List<skir.TypeParameter> parameters = const [],
    List<skir.NamedTypeTemplate> parents = const [],
  }) => skir.PublishedType(
    definition: skir.TypeDefinition(
      id: id,
      parameters: parameters,
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        abstract_: false,
      ),
      parents: parents,
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: skir.TypeDisplay(
      name: name,
      description: "$name for quest completion",
      icon: "mdi:gift",
      color: skir.Color(argb: 0xffffb300.toSigned(32)),
    ),
  );
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      resourceOperations: const [],
      resourceOperationContributions: const [],
      generation: skir.CatalogGeneration(value: "catalog:rewards"),
      types: [
        published(
          _variable,
          name: "Reward variable",
          parameters: [
            for (final (index, name) in [
              "Reward",
              if (twoArguments) "Bonus",
            ].indexed)
              skir.TypeParameter(
                key: skir.ParameterKey(owner: _variable, index: index),
                name: name,
                bounds: [
                  skir.TypeTemplate.createNamed(
                    definition: _reward,
                    arguments: const [],
                  ),
                ],
              ),
          ],
        ),
        published(_reward, name: "Reward"),
        for (final (id, name) in [
          (_coins, "Coins"),
          (_items, "Item bundle"),
          (_experience, "Experience"),
        ])
          published(id, name: name, parents: [rewardParent]),
      ],
      relations: const [],
      resourceDefinitions: const [],
      presentations: const [],
      presentationMaterials: const [],
      configuration: const [],
      diagnostics: const [],
      endpointBindings: const [],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
}

/// Composes Reward variable type arguments and reviews a scripted Realm
/// repair preview before staging it locally.
class AuthoredTypeArgumentEditorStory extends HookWidget {
  const AuthoredTypeArgumentEditorStory({
    this.twoArguments = false,
    this.chosen = false,
    this.outcome = TypePreviewOutcome.ready,
    this.enabled = true,
    this.width = 480,
    super.key,
  });

  final bool twoArguments;
  final bool chosen;
  final TypePreviewOutcome outcome;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final catalog = useMemoized(() => _catalog(twoArguments: twoArguments), [
      twoArguments,
    ]);
    final selection = useMemoized(
      () => skir.TypeSelection.createPending(
        definition: _variable,
        arguments: [
          if (chosen)
            skir.ArgumentSelection.wrapChosen(
              skir.TypeUse.wrapNamed(
                skir.NamedTypeUse(definition: _coins, arguments: const []),
              ),
            )
          else
            skir.ArgumentSelection.unfilled,
          if (twoArguments) skir.ArgumentSelection.unfilled,
        ],
      ),
      [twoArguments, chosen],
    );
    final status = useState("No type change staged");
    return FakeApp(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthoredTypeArgumentEditor(
              key: ValueKey((twoArguments, chosen)),
              selection: selection,
              catalog: catalog,
              enabled: enabled,
              disabledMessage: "Connect to the Realm to change type arguments",
              preview: (requested) async => switch (outcome) {
                TypePreviewOutcome.ready => skir.TypePreviewResult.createReady(
                  resource: _resource,
                  next: requested,
                  edit: skir.PreparedEdit(
                    catalog: catalog.snapshot.generation,
                    expectations: const [],
                    intents: const [],
                  ),
                  linkRepairs: const [],
                  clearedLocations: [
                    skir.ValueLocation(
                      resource: _resource,
                      path: editorRootPath.field("amount"),
                    ),
                  ],
                ),
                TypePreviewOutcome.rejected =>
                  skir.TypePreviewResult.wrapRejected([
                    skir.ValueProblem(
                      location: skir.ValueLocation(
                        resource: _resource,
                        path: editorRootPath.field("amount"),
                      ),
                      code: "reward_amount_in_use",
                    ),
                  ]),
              },
              commit: (_) async => const EditStageResult.staged(EditGroupId(1)),
              onStatus: (message) => status.value = message,
            ),
            Text(status.value),
          ],
        ),
      ),
    );
  }
}
