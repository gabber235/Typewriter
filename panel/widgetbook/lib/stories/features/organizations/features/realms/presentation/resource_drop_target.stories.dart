import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_resource_items.stories.dart";

@widgetbook.UseCase(name: "Drag entries onto a page", type: ResourceDropTarget)
Widget resourceDropTargetStory(BuildContext context) =>
    resourceDropTargetExample(
      compatible: context.knobs.boolean(
        label: "Page accepts the entries",
        initialValue: true,
      ),
      delayed: context.knobs.boolean(
        label: "Slow drop candidates",
        initialValue: false,
      ),
      dropEnabled: context.knobs.boolean(
        label: "Drop target enabled",
        initialValue: true,
      ),
    );

/// The compiled entry graph beside a Village evening page that accepts a
/// Move to drop. Candidates come once per drag from a story Realm.
Widget resourceDropTargetExample({
  bool compatible = true,
  bool delayed = false,
  bool dropEnabled = true,
}) => AuthoringFixtureApp(
  scenario: (compatible, delayed, dropEnabled),
  createDocument: _operationDocument,
  createCommands: (ref, transport) =>
      _commands(ref, transport, compatible: compatible, delayed: delayed),
  overrides: [
    resourceIssuesProvider.overrideWith((ref, scope) {
      final document = ref.watch(workingAuthoringDocumentProvider(scope));
      return document.mapUnready<ResourceIssues>() ??
          AsyncData(ResourceIssues.evaluate(document: document.requireValue));
    }),
    realmSurfaceNavigationProvider.overrideWith(_StoryNavigation.new),
    realmInteractionProvider.overrideWithValue(
      const RealmInteractionState(connectionState: RealmConnectionState.online),
    ),
  ],
  child: CompiledEntryGraphScene(dropEnabled: dropEnabled),
);

@widgetbook.UseCase(name: "Hover states", type: ResourceDropHighlight)
Widget resourceDropHighlightStory(BuildContext context) {
  final state = context.knobs.object.dropdown(
    label: "State",
    options: const ["Idle", "Accepted", "Rejected"],
    initialOption: "Accepted",
  );
  return FakeApp(
    child: Center(
      child: SizedBox(
        width: 280,
        child: ResourceDropHighlight(
          hover: switch (state) {
            "Accepted" => const ResourceDropHover(
              accepted: true,
              hint: "Move here",
            ),
            "Rejected" => const ResourceDropHover(rejected: true),
            _ => ResourceDropHover.idle,
          },
          child: const ListTile(
            leading: Icon(Icons.article_outlined),
            title: Text("Village evening"),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Hint", type: DropHintChip)
Widget dropHintChipStory(BuildContext context) => FakeApp(
  child: Center(
    child: DropHintChip(
      hint: context.knobs.string(label: "Hint", initialValue: "Move here"),
    ),
  ),
);

@widgetbook.UseCase(name: "Several offers", type: DropChooser)
Widget dropChooserStory(BuildContext context) {
  final count = context.knobs.int.slider(
    label: "Offers",
    initialValue: 2,
    min: 2,
    max: 3,
  );
  return FakeApp(
    child: Center(
      child: DropChooser(
        offers: [
          DropOffer.operation(
            operation: _definition(
              "MoveToOwner",
              label: "Move to",
              icon: "mdi:folder-move-outline",
              order: 10,
              hint: "Move here",
            ),
            destination: compiledEntryDestinationId,
          ),
          DropOffer.operation(
            operation: _definition(
              "LinkWith",
              label: "Link with",
              icon: "mdi:link-variant",
              order: 20,
              hint: "Link",
            ),
            destination: compiledEntryDestinationId,
          ),
          if (count > 2)
            DropOffer.operation(
              operation: _definition(
                "LinkWithDuplicate",
                label: "Link with duplicate",
                icon: "mdi:link-variant-plus",
                order: 30,
                hint: "Link a copy",
              ),
              destination: compiledEntryDestinationId,
            ),
        ],
        onChoose: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Dragged resources", type: ResourceDragFeedback)
Widget resourceDragFeedbackStory(BuildContext context) => FakeApp(
  child: Center(
    child: ResourceDragFeedback(
      label: context.knobs.string(label: "Label", initialValue: "Greeting"),
      icon: skir.Icon.wrapIconify("mdi:message-text-outline"),
      accent: Colors.teal,
      count: context.knobs.int.slider(
        label: "Resources",
        initialValue: 1,
        min: 1,
        max: 5,
      ),
    ),
  ),
);

final _inputId = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "operation-story",
    name: "Destination",
  ),
  revision: 1,
);
final _inputType = skir.NamedTypeUse(definition: _inputId, arguments: const []);

skir.ResourceOperationId _id(String name) => skir.ResourceOperationId(
  artifact: "typewriter",
  sourcePart: "main",
  declaration: "com.typewritermc.operations.$name",
);

skir.ResourceOperationDefinition _definition(
  String name, {
  required String label,
  required String icon,
  int order = 0,
  String? hint,
}) {
  final destructive = name == "Delete";
  return skir.ResourceOperationDefinition(
    id: _id(name),
    targets: skir.OperationTargets(
      subject: skir.ResourceTarget.anyResource,
      cardinality: skir.OperationCardinality.selection,
    ),
    capability: skir.CapabilityId(value: "story:$name"),
    drop: hint == null
        ? null
        : skir.OperationDrop(
            input: editorRootPath.field("destination"),
            hint: hint,
          ),
    presentation: skir.OperationPresentation(
      label: label,
      description: "Apply to the captured resources",
      icon: icon,
      group: destructive
          ? skir.OperationGroup.destructive
          : skir.OperationGroup.organize,
      order: order,
      tone: destructive
          ? skir.HeaderActionTone.destructive
          : skir.HeaderActionTone.neutral,
      confirmation: destructive
          ? skir.OperationConfirmation(
              title: "Delete resources",
              message: "Remove the captured resources from this story?",
              confirmationLabel: "Delete",
            )
          : null,
      inspector: skir.OperationInspector.wrapButton(
        destructive ? skir.ButtonVariant.filled : skir.ButtonVariant.outlined,
      ),
      shortcut: destructive ? skir.OperationShortcut.delete : null,
    ),
  );
}

final _operations = [
  _definition(
    "MoveToOwner",
    label: "Move to",
    icon: "mdi:folder-move-outline",
    order: 10,
    hint: "Move here",
  ),
  _definition("Delete", label: "Delete", icon: "mdi:delete-outline"),
];

AuthoringDocument _operationDocument() {
  final document = compiledEntryNodeDocument(graphEditor: true);
  final snapshot = document.catalog.snapshot.toMutable();
  final owner = skir.FieldOwner(definition: _inputId, name: "destination");
  final fieldType = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  snapshot.types = [
    ...snapshot.types,
    skir.PublishedType(
      searchKey: null,
      placementField: null,
      display: defaultTypeDisplay(""),
      status: skir.DeclarationStatus.ready,
      definition: skir.TypeDefinition(
        id: _inputId,
        parameters: const [],
        parents: const [],
        representation: skir.RepresentationTemplate.createRecord(
          abstract_: false,
          fields: [
            skir.FieldDeclaration(
              owner: owner,
              type: fieldType,
              overrides: const [],
              hasConstructorDefault: false,
            ),
          ],
        ),
      ),
      effectiveFields: [
        skir.EffectiveFieldTemplate(
          key: "destination",
          owner: owner,
          type: fieldType,
          rules: const [],
        ),
      ],
      ancestorTemplates: const [],
    ),
  ];
  snapshot.capabilities = [
    ...snapshot.capabilities,
    for (final operation in _operations)
      skir.CapabilityDefinition.createAuthoring(
        capabilityId: operation.capability,
        targets: operation.targets,
        input: operation.drop == null
            ? null
            : skir.OperationInputDefinition(
                type: skir.TypeUse.wrapNamed(_inputType),
                presentation: null,
              ),
      ),
  ];
  snapshot.resourceOperations = _operations;
  return document.copyWith(catalog: CheckedEditorCatalog(snapshot.toFrozen()));
}

AuthoredResourceCommands _commands(
  Ref ref,
  ScriptedAuthoringTransport transport, {
  required bool compatible,
  required bool delayed,
}) {
  AuthoringDocument document() => ref
      .read(realmEditingProvider(ref.read(selectedAuthoringScopeProvider)!))
      .document;
  bool entries(skir.OperationInvocation invocation) => invocation.targets.every(
    (id) => id == compiledEntryFirstId || id == compiledEntrySecondId,
  );
  return fixtureAuthoringCommands(
    transport,
    resolveResourceOperations: (request) async =>
        skir.ResolveResourceOperationsResult.createResolved(
          operations: [
            for (final operation in _operations)
              if (operation.drop == null || entries(request.invocation))
                skir.ResolvedResourceOperation(
                  definition: operation,
                  availability: skir.OperationAvailability.enabled,
                ),
          ],
        ),
    resolveDropCandidates: (request) async {
      if (delayed) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
      return skir.ResolveDropCandidatesResult.wrapResolved([
        skir.DropCandidates(
          operation: _id("MoveToOwner"),
          destinations: [
            if (compatible && entries(request.invocation))
              compiledEntryDestinationId,
          ],
          complete: true,
        ),
      ]);
    },
    prepareAuthoringAction: (request) async {
      final edit = AuthoringEdit.fromDocument(document());
      if (request.capability.value == "story:Delete") {
        for (final id in request.invocation.targets) {
          edit.delete(id);
        }
      } else {
        final destination = request.input
            ?.authoredField("destination")
            ?.authoredString;
        if (destination == null || destination.isEmpty) {
          return skir.AuthoringActionResult.createNeedsInput(
            invocationId: request.invocation.invocationId,
            inputRevision: request.inputRevision,
            normalizedInput: request.input,
            choices: const [],
            problems: [
              skir.OperationInputProblem(
                path: editorRootPath.field("destination"),
                code: "required",
                message: "Enter page:evening to move to Village evening",
              ),
            ],
          );
        }
        final target = skir.ResourceId(value: destination);
        if (document().entry(target) == null) {
          return skir.AuthoringActionResult.createUnavailableError(
            diagnostics: [
              skir.AuthoringDiagnostic(
                code: "fixture_unavailable",
                message: "The destination does not exist",
                resource: null,
                path: null,
              ),
            ],
          );
        }
        for (final id in request.invocation.targets) {
          final path = editorRootPath.field("page");
          final endpoint = document().catalog
              .endpointBindingsAt(document().resource(id)!.configuration, path)
              .single
              .template
              .endpoint;
          edit.connect(
            skir.LinkOccurrence(
              id: skir.LinkOccurrenceId(
                endpoint: endpoint,
                location: skir.ValueLocation(resource: id, path: path),
              ),
              source: id,
              target: skir.LinkTarget(resource: target, opposite: null),
            ),
            target,
          );
        }
      }
      return skir.AuthoringActionResult.createPreview(
        invocationId: request.invocation.invocationId,
        inputRevision: request.inputRevision,
        edit: edit.prepare(),
        confirmation: request.capability.value == "story:Delete"
            ? skir.OperationConfirmation(
                title: "Delete resources",
                message: "Remove the captured resources from this story?",
                confirmationLabel: "Delete",
              )
            : null,
        selection: skir.OperationSelectionEffect.unchanged,
      );
    },
  );
}

/// Selects opened resources in place: the story has no routes to open.
final class _StoryNavigation extends RealmSurfaceNavigation {
  _StoryNavigation(super.ref);

  @override
  Future<bool> open(
    AuthoringScope scope,
    skir.ResourceId resource, {
    bool Function()? isCurrent,
  }) async {
    if (!(isCurrent?.call() ?? true)) return false;
    ref.read(selectionProvider.notifier).selectAll([
      AuthoringResourceIdentifier.inScope(scope, resource),
    ]);
    return true;
  }
}
