import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

enum CollectionEditorExample {
  textList,
  textSet,
  scalarMap,
  authoredSteps,
  fallbackSteps,
  structuredMap,
  nestedLists,
  unfinishedSteps,
  directLinks,
}

/// Owns a real authored draft so collection stories and tests share writes.
final class CollectionEditorScenario extends ChangeNotifier {
  CollectionEditorScenario({
    this.example = CollectionEditorExample.textList,
    bool longTitles = false,
    bool empty = false,
    this.confirmRemoval = false,
    this.capabilities = const PortablePresentationCapabilities(),
    skir.PresentationNode Function(skir.PresentationNode)? transformLayout,
  }) {
    final initialCatalog = example == CollectionEditorExample.directLinks
        ? null
        : _catalog(example);
    final initial = example == CollectionEditorExample.directLinks
        ? _linkDocument(empty: empty)
        : AuthoringDocument(
            catalog: initialCatalog!,
            entries: {
              resource: skir.AuthoringResource(
                id: resource,
                definition: skir.ResourceDefinitionId(
                  value: "fixture.collection",
                ),
                content: skir.AuthoringRecord(
                  configuration: skir.TypeSelection.wrapComplete(_use("Owner")),
                  fields: [
                    skir.FieldValue(
                      name: "entries",
                      value: skir.DataValue.createNamed(
                        actualType: _use(_entryType(example)),
                        payload: _initialValue(
                          example,
                          longTitles: longTitles,
                          empty: empty,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            },
            links: const [],
          );
    catalog = initial.catalog;
    transport = ScriptedAuthoringTransport(AsyncData(initial));
    workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: submissions,
      initial: initial,
    );
    binding = workspace.attach(
      ownedResource,
      policy: EditorCommitPolicy.applyResource,
    );
    host = AuthoredPresentationHost(
      resource: ownedResource,
      source: initial,
      material:
          (skir.PresentationMaterial.mutable()
                ..layout = transformLayout?.call(_layout()) ?? _layout())
              .toFrozen(),
      role: skir.PresentationRole.workspaceEditor,
      budget: skir.EvaluationBudget(maxSteps: 2000, maxCollectionItems: 200),
      capabilities: capabilities,
      edit: binding,
    );
    workspace.addListener(notifyListeners);
  }

  static final resource = skir.ResourceId(value: "fixture:collection");
  static final first = skir.ItemId(value: "first");
  static final second = skir.ItemId(value: "second");
  static final third = skir.ItemId(value: "third");
  static final itemBinding = skir.ExpressionBindingId(value: "fixture.item");
  static final entriesPath = editorRootPath.field("entries");
  final CollectionEditorExample example;
  final bool confirmRemoval;
  final PortablePresentationCapabilities capabilities;
  final submissions = ScopedWorkSession();
  late final CheckedEditorCatalog catalog;
  late final ScriptedAuthoringTransport transport;
  late final RealmEditing workspace;
  late final RealmEditingBinding binding;
  late final AuthoredPresentationHost host;

  skir.ResourceId get ownedResource =>
      example == CollectionEditorExample.directLinks
      ? compiledInheritanceTagId
      : resource;
  String get field =>
      example == CollectionEditorExample.directLinks ? "parents" : "entries";
  skir.DataValue get value =>
      workspace.document.resource(ownedResource)!.authoredField(field)!;

  skir.PresentationNode _layout() {
    final reference = skir.BindingRef(
      bindingId: configuredValueBindingId,
      path: editorRootPath.field(field),
    );
    final control =
        (skir.BoundControl.mutable()
              ..binding = reference
              ..label = textLiteral("Quest entries"))
            .toFrozen();
    final item = example == CollectionEditorExample.authoredSteps
        ? _authoredStep(reference)
        : example == CollectionEditorExample.nestedLists && confirmRemoval
        ? _authoredStep(reference, title: textLiteral("Nested steps"))
        : null;
    final element = switch (example) {
      CollectionEditorExample.directLinks =>
        skir.PresentationElement.wrapLinkInput(
          (skir.LinkControl.mutable()
                ..control = control
                ..allowReorder = false)
              .toFrozen(),
        ),
      CollectionEditorExample.scalarMap ||
      CollectionEditorExample.structuredMap =>
        skir.PresentationElement.wrapMapInput(
          (skir.MapControl.mutable()
                ..control = control
                ..keyBindingId = skir.ExpressionBindingId(value: "fixture.key")
                ..valueBindingId = skir.ExpressionBindingId(
                  value: "fixture.mapValue",
                )
                ..allowAdd = true
                ..allowRemove = true)
              .toFrozen(),
        ),
      CollectionEditorExample.textSet => skir.PresentationElement.wrapSetInput(
        (skir.SetControl.mutable()
              ..control = control
              ..itemBindingId = itemBinding
              ..allowAdd = true
              ..allowRemove = true)
            .toFrozen(),
      ),
      _ => skir.PresentationElement.wrapListInput(
        (skir.ListControl.mutable()
              ..control = control
              ..itemBindingId = itemBinding
              ..itemPresentation = item
              ..allowAdd = true
              ..allowRemove = true
              ..allowReorder = true)
            .toFrozen(),
      ),
    };
    return skir.PresentationNode(
      nodeId: "fixture.collection",
      properties: skir.PresentationProperties.defaultInstance,
      element: element,
      header: null,
    );
  }

  skir.PresentationNode _authoredStep(
    skir.BindingRef collection, {
    skir.ExpressionNode? title,
  }) {
    final item = skir.BindingRef(bindingId: itemBinding, path: editorRootPath);
    return skir.PresentationNode(
      nodeId: "fixture.authoredStep",
      properties: skir.PresentationProperties.defaultInstance,
      element: skir.PresentationElement.createDefaultPresentation(
        control: (skir.BoundControl.mutable()..binding = item).toFrozen(),
        presentationId: null,
      ),
      header:
          (skir.PresentationHeader.mutable()
                ..title = skir.PresentationHeaderTitle.wrapText(
                  title ??
                      skir.ExpressionNode.createInput(
                        binding: itemBinding,
                        path: editorRootPath.field("name"),
                      ),
                )
                ..initiallyExpanded = false
                ..items = [
                  if (confirmRemoval)
                    skir.HeaderItem.createButton(
                      itemId: skir.HeaderItemId(
                        namespace: "fixture",
                        name: "remove",
                      ),
                      icon: textLiteral(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
                      ),
                      label: textLiteral("Remove step"),
                      tooltip: null,
                      action: skir.EditorAction.wrapLocal(
                        skir.LocalEditorAction.createRemoveListItem(
                          target: collection,
                          item: first,
                        ),
                      ),
                      priority: null,
                      visibleIf: null,
                      enabledIf: null,
                      tone: skir.HeaderActionTone.destructive,
                      confirmation: skir.HeaderActionConfirmation(
                        title: textLiteral("Remove this step?"),
                        message: textLiteral(
                          "The step will be removed from this draft.",
                        ),
                        confirmationLabel: textLiteral("Remove step"),
                      ),
                      placement: skir.HeaderActionPlacement.end,
                    ),
                ])
              .toFrozen(),
    );
  }

  @override
  void dispose() {
    workspace.removeListener(notifyListeners);
    host.dispose();
    binding.detach();
    workspace.dispose();
    transport.dispose();
    submissions.dispose();
    super.dispose();
  }
}

final class CollectionEditorScenarioView extends StatelessWidget {
  const CollectionEditorScenarioView({
    required this.scenario,
    this.readOnly = false,
    this.enabled = true,
    this.host,
    super.key,
  });

  final CollectionEditorScenario scenario;
  final bool readOnly;
  final bool enabled;
  final PortablePresentationHost? host;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: scenario,
    builder: (context, _) {
      scenario.host.update(
        source: scenario.workspace.document,
        capabilities: scenario.capabilities,
        available: enabled,
        readOnly: readOnly,
      );
      return PortablePresentationRenderer(host: host ?? scenario.host);
    },
  );
}

skir.TypeDefinitionId _id(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "collection.fixture",
    name: name,
  ),
  revision: 1,
);
skir.NamedTypeUse _use(String name) =>
    skir.NamedTypeUse(definition: _id(name), arguments: const []);
skir.TypeTemplate _named(String name) =>
    skir.TypeTemplate.createNamed(definition: _id(name), arguments: const []);

skir.DataValue _initialValue(
  CollectionEditorExample example, {
  required bool longTitles,
  bool empty = false,
}) {
  if (empty) {
    return switch (example) {
      CollectionEditorExample.scalarMap ||
      CollectionEditorExample.structuredMap => skir.DataValue.createMapValue(
        rows: const [],
      ),
      CollectionEditorExample.textSet => skir.DataValue.createSetValue(
        items: const [],
      ),
      _ => skir.DataValue.createListValue(items: const []),
    };
  }
  final names = [
    longTitles
        ? "Arrival at the ancient observatory beyond the northern valley"
        : "Arrival",
    "Discovery",
    "Return",
  ];
  skir.DataValue text(String value) => skir.DataValue.wrapStringValue(value);
  skir.DataValue step(int index) => skir.DataValue.createNamed(
    actualType: _use("Step"),
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(name: "name", value: text(names[index])),
        skir.FieldValue(
          name: "amount",
          value: skir.DataValue.wrapInteger("${index + 1}"),
        ),
      ],
    ),
  );
  final ids = [
    CollectionEditorScenario.first,
    CollectionEditorScenario.second,
    CollectionEditorScenario.third,
  ];
  final scalarItems = [
    for (var index = 0; index < 3; index++)
      skir.ListItem(id: ids[index], value: text(names[index])),
  ];
  return switch (example) {
    CollectionEditorExample.textList => skir.DataValue.createListValue(
      items: scalarItems,
    ),
    CollectionEditorExample.textSet => skir.DataValue.createSetValue(
      items: scalarItems,
    ),
    CollectionEditorExample.scalarMap ||
    CollectionEditorExample.structuredMap => skir.DataValue.createMapValue(
      rows: [
        for (var index = 0; index < 2; index++)
          skir.MapRow(
            id: ids[index],
            key: text(index == 0 ? "arrival" : "discovery"),
            value: example == CollectionEditorExample.scalarMap
                ? text(names[index])
                : step(index),
          ),
      ],
    ),
    CollectionEditorExample.nestedLists => skir.DataValue.createListValue(
      items: [
        for (var index = 0; index < 2; index++)
          skir.ListItem(
            id: ids[index],
            value: skir.DataValue.createNamed(
              actualType: _use("TextList"),
              payload: skir.DataValue.createListValue(
                items: [scalarItems[index]],
              ),
            ),
          ),
      ],
    ),
    _ => skir.DataValue.createListValue(
      items: [
        for (var index = 0; index < 2; index++)
          skir.ListItem(
            id: ids[index],
            value:
                example == CollectionEditorExample.unfinishedSteps && index == 0
                ? skir.DataValue.unfilled
                : step(index),
          ),
      ],
    ),
  };
}

CheckedEditorCatalog _catalog(CollectionEditorExample example) {
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final integer = skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  );
  skir.PublishedType published(
    String name,
    skir.RepresentationTemplate representation, {
    Map<String, skir.TypeTemplate> fields = const {},
  }) => skir.PublishedType(
    searchKey: null,
    placementField: null,
    definition: skir.TypeDefinition(
      id: _id(name),
      parameters: const [],
      parents: const [],
      representation: representation,
    ),
    status: skir.DeclarationStatus.ready,
    display: defaultTypeDisplay(""),
    ancestorTemplates: const [],
    effectiveFields: [
      for (final field in fields.entries)
        skir.EffectiveFieldTemplate(
          key: field.key,
          owner: skir.FieldOwner(definition: _id(name), name: field.key),
          type: field.value,
          rules: const [],
        ),
    ],
  );
  skir.PublishedType record(
    String name,
    Map<String, skir.TypeTemplate> fields,
  ) => published(
    name,
    skir.RepresentationTemplate.createRecord(
      abstract_: false,
      fields: [
        for (final field in fields.entries)
          skir.FieldDeclaration(
            owner: skir.FieldOwner(definition: _id(name), name: field.key),
            type: field.value,
            overrides: const [],
            hasConstructorDefault: false,
          ),
      ],
    ),
    fields: fields,
  );
  final entryType = _entryType(example);
  return CheckedEditorCatalog(
    (skir.EditorCatalogWireSnapshot.mutable()
          ..generation = skir.CatalogGeneration(value: "collection.fixture")
          ..types = [
            record("Owner", {"entries": _named(entryType)}),
            record("Step", {"name": text, "amount": integer}),
            published(
              "TextList",
              skir.RepresentationTemplate.createSequence(
                item: text,
                kind: skir.CollectionKind.list,
              ),
            ),
            published(
              "TextSet",
              skir.RepresentationTemplate.createSequence(
                item: text,
                kind: skir.CollectionKind.set_,
              ),
            ),
            published(
              "TextMap",
              skir.RepresentationTemplate.createMapping(key: text, value: text),
            ),
            published(
              "StepList",
              skir.RepresentationTemplate.createSequence(
                item: _named("Step"),
                kind: skir.CollectionKind.list,
              ),
            ),
            published(
              "StepMap",
              skir.RepresentationTemplate.createMapping(
                key: text,
                value: _named("Step"),
              ),
            ),
            published(
              "NestedList",
              skir.RepresentationTemplate.createSequence(
                item: _named("TextList"),
                kind: skir.CollectionKind.list,
              ),
            ),
          ])
        .toFrozen(),
  );
}

AuthoringDocument _linkDocument({required bool empty}) {
  final targets = [
    for (final name in ["Arrival", "Discovery"])
      Tag(
        tagId: skir.ResourceId(value: "tag:${name.toLowerCase()}"),
        name: name,
        color: const Color(0xff69a9ff),
        parentIds: const [],
        placement: const GraphPlacement(x: 0, y: 0, width: 4, height: 1),
      ),
  ];
  return compiledTagInheritanceDocument(
    tags: targets,
    roots: empty ? const [] : targets.map((tag) => tag.tagId).toList(),
  );
}

String _entryType(CollectionEditorExample example) => switch (example) {
  CollectionEditorExample.textList => "TextList",
  CollectionEditorExample.textSet => "TextSet",
  CollectionEditorExample.scalarMap => "TextMap",
  CollectionEditorExample.structuredMap => "StepMap",
  CollectionEditorExample.nestedLists => "NestedList",
  _ => "StepList",
};
