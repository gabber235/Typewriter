import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/presentation/authored_page_graph_node.stories.dart";

@widgetbook.UseCase(
  name: "Remote hover feedback",
  type: ResourceOperationDropTarget,
)
Widget resourceOperationDropTargetStory(BuildContext context) {
  final available = context.knobs.boolean(
    label: "Remote target compatible",
    initialValue: true,
  );
  final delayed = context.knobs.boolean(
    label: "Delayed hover check",
    initialValue: true,
  );
  return resourceOperationDropTargetExample(
    available: available,
    delayed: delayed,
  );
}

Widget resourceOperationDropTargetExample({
  bool available = true,
  bool delayed = true,
  bool dropEnabled = true,
}) => AuthoringFixtureApp(
  scenario: (available, delayed, dropEnabled),
  createDocument: _operationDocument,
  createCommands: (ref, transport) =>
      _commands(ref, transport, available, delayed),
  overrides: [
    resourceIssuesProvider.overrideWith((ref, scope) {
      final document = ref.watch(workingAuthoringDocumentProvider(scope));
      return document.mapUnready<ResourceIssues>() ??
          AsyncData(ResourceIssues.evaluate(document: document.requireValue));
    }),
    authoringResourceNavigationRegistryProvider.overrideWithValue(
      AuthoringResourceNavigationRegistry({
        for (final handler in [
          skir.AuthoringNavigationHandler.book,
          skir.AuthoringNavigationHandler.page,
          skir.AuthoringNavigationHandler.pageElement,
        ])
          handler: const _StoryNavigation(),
      }),
    ),
    realmInteractionProvider.overrideWithValue(
      const RealmInteractionState(connectionState: RealmConnectionState.online),
    ),
  ],
  child: CompiledEntryGraphScene(dropEnabled: dropEnabled),
);

final _inputId = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "operation-story",
    name: "Destination",
  ),
  revision: 1,
);
final _inputType = skir.NamedTypeUse(definition: _inputId, arguments: const []);

AuthoringDocument _operationDocument() {
  final document = compiledEntryNodeDocument(graphEditor: true);
  final snapshot = document.catalog.snapshot.toMutable();
  final owner = skir.FieldOwner(definition: _inputId, name: "destination");
  final fieldType = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  snapshot.types = [
    ...snapshot.types,
    skir.PublishedType(
      display: null,
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
    for (final key in ["moveToPage", "delete"])
      skir.CapabilityDefinition.createAuthoring(
        capabilityId: skir.CapabilityId(value: "story:$key"),
        targets: skir.OperationTargets.contributedSelection,
        input: key == "delete"
            ? null
            : skir.OperationInputDefinition(
                type: skir.TypeUse.wrapNamed(_inputType),
                presentation: null,
              ),
      ),
  ];
  snapshot.resourceOperations = [
    for (final key in ["open", "edit", "moveToPage", "delete"])
      skir.ResourceOperationDefinition(
        id: (resourceDeleteOperationId.toMutable()..local = key).toFrozen(),
        targets: key == "open" || key == "edit"
            ? skir.OperationTargets.contributedSingle
            : skir.OperationTargets.contributedSelection,
        presentation: skir.OperationPresentation(
          showInInspector: key != "edit",
          variant: switch (key) {
            "open" => skir.ButtonVariant.text,
            "delete" => skir.ButtonVariant.filled,
            _ => skir.ButtonVariant.outlined,
          },
          label: {
            "open": "Open",
            "edit": "Edit",
            "moveToPage": "Move to page",
            "delete": "Delete",
          }[key]!,
          description: key == "moveToPage"
              ? "Move the captured entries to another page"
              : "Apply to the captured resource",
          icon: {
            "open": "mdi:open-in-new",
            "edit": "mdi:pencil",
            "moveToPage": "mdi:file-move-outline",
            "delete": "mdi:delete-outline",
          }[key]!,
          group: key == "open"
              ? skir.OperationGroup.navigation
              : skir.OperationGroup.edit,
          order: 0,
          tone: key == "delete"
              ? skir.HeaderActionTone.destructive
              : skir.HeaderActionTone.neutral,
          confirmation: key == "delete"
              ? skir.OperationConfirmation(
                  title: "Delete resources",
                  message: "Remove the captured resources from this story?",
                  confirmationLabel: "Delete",
                )
              : null,
        ),
        action: key == "open" || key == "edit"
            ? skir.EditorAction.createNavigate(
                resource: skir.ExpressionNode.createInput(
                  binding: skir.ExpressionBindingId(value: "context:subject"),
                  path: editorRootPath,
                ),
                mode: key == "open"
                    ? skir.ResourceNavigationMode.open
                    : skir.ResourceNavigationMode.edit,
              )
            : skir.EditorAction.createAuthoring(
                capability: skir.CapabilityId(value: "story:$key"),
                targets: skir.ExpressionNode.createInput(
                  binding: skir.ExpressionBindingId(value: "context:selection"),
                  path: editorRootPath,
                ),
                initialInput: null,
              ),
      ),
  ];
  return document.copyWith(catalog: CheckedEditorCatalog(snapshot.toFrozen()));
}

AuthoredResourceCommands _commands(
  Ref ref,
  ScriptedAuthoringTransport transport,
  bool available,
  bool delayed,
) {
  AuthoringDocument document() => ref
      .read(realmEditingProvider(ref.read(selectedAuthoringScopeProvider)!))
      .document;
  return fixtureAuthoringCommands(
    transport,
    resolveResourceOperations: (request) async {
      final book =
          request.invocation.targets.singleOrNull == compiledEntryBookId;
      final entries = request.invocation.targets.every(
        (id) => id == compiledEntryFirstId || id == compiledEntrySecondId,
      );
      return skir.ResolveResourceOperationsResult.createResolved(
        primaryOperation:
            (resourceDeleteOperationId.toMutable()
                  ..local = book ? "open" : "edit")
                .toFrozen(),
        operations: [
          for (final operation
              in document().catalog.snapshot.resourceOperations)
            if ((operation.id.local != "open" || book) &&
                (operation.id.local != "edit" || !book) &&
                (operation.id.local != "moveToPage" || entries))
              skir.ResolvedResourceOperation(
                definition: operation,
                availability: skir.OperationAvailability.enabled,
              ),
        ],
      );
    },
    prepareAuthoringAction: (request) async {
      if (delayed) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
      }
      if (!available && request.capability.value == "story:moveToPage") {
        return _unavailable("This destination is unavailable");
      }
      final edit = AuthoringEdit.fromDocument(document());
      if (request.capability.value == "story:delete") {
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
          return _unavailable("The destination does not exist");
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
        confirmation: null,
        selection: skir.OperationSelectionEffect.unchanged,
      );
    },
  );
}

final class _StoryNavigation implements AuthoringResourceNavigationAdapter {
  const _StoryNavigation();
  @override
  Future<void> open(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() ?? true) {
      ref.read(selectionProvider.notifier).selectAll([resource]);
    }
  }

  @override
  Future<void> reveal(
    Ref ref,
    AuthoringResourceIdentifier resource, {
    bool Function()? isCurrent,
  }) => open(ref, resource, isCurrent: isCurrent);
}

skir.AuthoringActionResult _unavailable(String message) =>
    skir.AuthoringActionResult.createUnavailable(
      diagnostics: [
        skir.AuthoringDiagnostic(
          code: "fixture_unavailable",
          message: message,
          resource: null,
          path: null,
        ),
      ],
    );
