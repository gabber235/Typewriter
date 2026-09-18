import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Complete editor", type: ElementCreationDialog)
Widget materializationPromptUseCase(BuildContext context) => FakeApp(
  overrides: [
    editorRealmRuntimeProvider.overrideWithValue(_materializationRuntime),
  ],
  child: const _MaterializationStory(),
);

final class _MaterializationStory extends StatefulWidget {
  const _MaterializationStory();

  @override
  State<_MaterializationStory> createState() => _MaterializationStoryState();
}

final class _MaterializationStoryState extends State<_MaterializationStory> {
  late final CreationDraft draft;

  @override
  void initState() {
    super.initState();
    draft = CreationDraft(
      rootType: _creationType,
      registry: _materializationRegistry,
      fixedValues: {
        const MaterializationLocation(["field:id"]): const StringValue(
          "widgetbook",
        ),
        const MaterializationLocation(["field:name"]): const StringValue(
          "Quest objective",
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) => ElementCreationDialog(
    title: "Create quest objective",
    draft: draft,
    presentations: const [],
    origins: [recordId("page:widgetbook_origin")],
    onCancel: () {},
    onCreate: (_) {},
  );

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }
}

const _creationType = RecordType(
  fields: {
    "id": TypeField(name: "id", type: StringType()),
    "name": TypeField(name: "name", type: StringType()),
    "target": TypeField(
      name: "target",
      type: ReferenceType(target: _elementType),
    ),
    "identifier": TypeField(
      name: "identifier",
      type: StringType(
        minimumLength: 3,
        maximumLength: 24,
        patterns: [r"^[a-z][a-z0-9_]+$"],
      ),
    ),
    "priority": TypeField(
      name: "priority",
      type: EnumType(
        valueType: StringType(),
        values: [
          StringValue("optional"),
          StringValue("recommended"),
          StringValue("required"),
        ],
      ),
    ),
    "audience": TypeField(name: "audience", type: NamedType(_audienceType)),
    "objectives": TypeField(
      name: "objectives",
      type: ListType(
        element: ReferenceType(target: _elementType),
        minimumLength: 2,
        maximumLength: 5,
        unique: true,
      ),
    ),
    "variables": TypeField(
      name: "variables",
      type: MapType(
        key: StringType(),
        value: ReferenceType(target: _elementType),
        minimumLength: 1,
        maximumLength: 4,
      ),
    ),
  },
);

final _materializationRegistry = TypeRegistry(
  TypeCatalog([
    ...referenceResourceTypes.definitions,
    const TypeDefinition(
      id: _audienceType,
      kind: NominalTypeKind.openAbstract,
      representation: RecordType(fields: {}),
    ),
    const TypeDefinition(
      id: _playerAudienceType,
      kind: NominalTypeKind.concrete,
      parents: [_audienceType],
      representation: RecordType(
        fields: {
          "player": TypeField(
            name: "player",
            type: ReferenceType(target: _elementType),
          ),
        },
      ),
    ),
    const TypeDefinition(
      id: _permissionAudienceType,
      kind: NominalTypeKind.concrete,
      parents: [_audienceType],
      representation: RecordType(
        fields: {
          "permission": TypeField(
            name: "permission",
            type: StringType(minimumLength: 3),
          ),
        },
      ),
    ),
  ]),
);

final _materializationRuntime = EditorRealmRuntime(
  actions: RealmActionCapabilities(
    execute: (_, _) async => const RealmCommandResult.success([]),
  ),
  presentationSearch: RealmPresentationSearchCapabilities(
    source: ({
      required provider,
      required queryBindingId,
      required expressions,
      required registry,
      required budget,
      required providerKey,
    }) => MockSearchSource(),
  ),
  references: ReferenceAuthoringCapabilities(
    search: ({required target, required origins, required registry}) =>
        MockSearchSource(nodes: _referenceNodes),
    resolve: ({required target, required ids, required registry}) async => [
      for (final id in ids)
        ReferenceResourceSummary(
          id: id,
          exists: true,
          title: _referenceTitles[id] ?? id.toSurrealQl(),
          subtitle: "Element on widgetbook_origin",
        ),
    ],
  ),
);

final _referenceTitles = {
  recordId("element:mayor_greeting"): "Mayor greeting",
  recordId("element:start_main_quest"): "Start main quest",
  recordId("element:reward_player"): "Reward player",
};

final _referenceNodes = [
  for (final entry in _referenceTitles.entries)
    SearchNode.result(
      result: SearchResult(
        id: entry.key.toSurrealQl(),
        type: presentationSearchResultType,
        title: entry.value,
        subtitle: "Element on widgetbook_origin",
        payload: PresentationSearchResultPayload(
          selectedValue: ReferenceValue(entry.key),
          presentation: PresentationNode(
            id: "materialization.${entry.key.id}",
            element: TextElement(entry.value.asStringLiteral),
          ),
          expressions: const ExpressionContext(
            bindings: BindingEnvironment({}),
          ),
          providerKey: "widgetbook.materialization.references",
        ),
      ),
    ),
];

const _elementType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "com.typewritermc.elements", name: "Element"),
  revision: 1,
);
const _audienceType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "widgetbook", name: "Audience"),
  revision: 1,
);
const _playerAudienceType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "widgetbook", name: "PlayerAudience"),
  revision: 1,
);
const _permissionAudienceType = ResolvedTypeRef(
  id: TypeId.qualified(namespace: "widgetbook", name: "PermissionAudience"),
  revision: 1,
);
