import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// What the Realm answers to a type argument preview.
enum _PreviewOutcome { ready, rejected }

@widgetbook.UseCase(
  name: "Reward type arguments",
  type: AuthoredTypeArgumentEditor,
)
Widget authoredTypeArgumentEditorUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    _TypeArgumentEditor(
      twoArguments: context.knobs.boolean(
        label: "Second argument",
        initialValue: false,
      ),
      chosen: context.knobs.boolean(
        label: "First argument chosen",
        initialValue: false,
      ),
      outcome: context.knobs.object.dropdown(
        label: "Realm preview",
        options: _PreviewOutcome.values,
        initialOption: _PreviewOutcome.ready,
        labelBuilder: (outcome) => switch (outcome) {
          _PreviewOutcome.ready => "Ready",
          _PreviewOutcome.rejected => "Rejected",
        },
      ),
      enabled: context.knobs.boolean(
        label: "Realm connected",
        initialValue: true,
      ),
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 480,
        min: 320,
        max: 720,
      ),
    ),
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
    name: "",
    extension_: "",
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: id,
      parameters: parameters,
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        form: skir.RecordForm.concrete,
      ),
      parents: parents,
    ),
    status: skir.DeclarationStatus.ready,
    effectiveFields: const [],
    ancestorTemplates: parents,
    display: skir.TypeDisplay(
      name: name,
      description: "$name for quest completion",
      icon: skir.Icon.wrapIconify("mdi:gift"),
      color: skir.Color(argb: 0xffffb300.toSigned(32)),
    ),
  );
  return CheckedEditorCatalog(
    skir.EditorCatalog(
      resourceDisplays: const [],
      resourceOperations: const [],
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
      realmRoot: skir.TypeDefinitionId.defaultInstance,
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

/// Composes Reward variable type arguments and reviews the Realm's repair
/// preview before staging it locally; the line below reports the outcome
/// the editor announces.
class _TypeArgumentEditor extends HookWidget {
  const _TypeArgumentEditor({
    this.twoArguments = false,
    this.chosen = false,
    this.outcome = _PreviewOutcome.ready,
    this.enabled = true,
    this.width = 480,
  });

  final bool twoArguments;
  final bool chosen;
  final _PreviewOutcome outcome;
  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final catalog = useMemoized(() => _catalog(twoArguments: twoArguments), [
      twoArguments,
    ]);
    final selection = useMemoized(() {
      final pending = selectionOfDefinition(_variable);
      return chosen
          ? pending.withChosen(
              0,
              skir.TypeUse.wrapNamed(
                skir.NamedTypeUse(definition: _coins, arguments: const []),
              ),
            )
          : pending;
    }, [twoArguments, chosen]);
    final status = useState("No type change staged");
    return SizedBox(
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
              _PreviewOutcome.ready =>
                skir.PreviewTypeArgumentChangeResponse.createReady(
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
              _PreviewOutcome.rejected =>
                skir.PreviewTypeArgumentChangeResponse.wrapRejectedError([
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
    );
  }
}
