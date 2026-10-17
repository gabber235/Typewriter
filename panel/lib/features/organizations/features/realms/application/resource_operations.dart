import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_operations.g.dart";

/// Resolves one complete operation set against a coherent working observation.
@riverpod
Future<skir.ResolvedResourceOperations> resourceOperations(
  Ref ref,
  AuthoringScope scope,
  skir.OperationInvocation invocation,
) async {
  ref.watch(workingAuthoringDocumentProvider(scope));
  final workspace = ref.read(realmEditingProvider(scope));
  final commands = ref.watch(authoredResourceCommandsProvider(scope));
  for (var attempt = 0; attempt < 2; attempt++) {
    final result = await commands.resolveResourceOperations(
      skir.ResolveResourceOperationsRequest(
        invocation: invocation,
        context: workspace.captureOperationContext().context,
      ),
    );
    if (!ref.mounted) {
      throw StateError("The operation observation was replaced");
    }
    switch (result) {
      case skir.ResolveResourceOperationsResult_resolvedWrapper(:final value):
        return value;
      case skir.ResolveResourceOperationsResult_staleObservationWrapper():
        await workspace.refreshConfirmed();
      default:
        throw StateError(
          "Resource operations are unavailable. Refresh the Realm",
        );
    }
  }
  throw StateError("Saved resources changed again. Refresh the Realm");
}

/// Captures ownership occurrences independently of presentation widget ancestry.
skir.OperationInvocation captureResourceOperationInvocation({
  required AuthoringDocument document,
  required Iterable<skir.ResourceId> targets,
  skir.OperationOrigin? origin,
  skir.InvocationId? invocationId,
}) {
  final ids = targets.toSet().toList(growable: false);
  final parents = document.relations;
  final owners = {
    for (final resource in ids) ...parents.parents[resource] ?? const [],
  };
  final occurrences = <skir.LinkOccurrence>[];
  for (final link in document.links) {
    final contract = document.catalog.snapshot.relations
        .where((contract) => contract.id == link.contract)
        .firstOrNull;
    if (contract == null ||
        !contract.families.any(
          (family) => family.value == "resource.ownership",
        )) {
      continue;
    }
    final firstOwns =
        contract.first.cardinality == skir.EndpointCardinality.one;
    final owner = firstOwns ? link.first : link.second;
    final child = firstOwns ? link.second : link.first;
    if (!ids.contains(child)) continue;
    final path = firstOwns ? link.firstLocation : link.secondLocation;
    if (path == null) continue;
    occurrences.add(
      skir.LinkOccurrence(
        id: skir.LinkOccurrenceId(
          endpoint: firstOwns ? contract.first.id : contract.second.id,
          location: skir.ValueLocation(resource: owner, path: path),
        ),
        source: owner,
        target: skir.LinkTarget(
          resource: child,
          opposite: firstOwns ? link.secondLocation : link.firstLocation,
        ),
      ),
    );
  }
  return skir.OperationInvocation(
    invocationId: invocationId ?? skir.InvocationId(value: const Uuid().v4()),
    catalog: document.generation,
    targets: ids,
    origin:
        origin ??
        skir.OperationOrigin(
          container: owners.length == 1 ? owners.single : null,
          occurrences: occurrences,
        ),
  );
}

final resourceDeleteOperationId = skir.ResourceOperationId(
  artifact: "typewriter",
  sourcePart: "main",
  declaration: "com.typewritermc.library.CoreResourceOperations",
  local: "delete",
);

/// Projects Realm affordances while retaining generic service operations.
List<SelectionOperation> selectionOperationsFor(
  WidgetRef ref,
  BuildContext context,
  List<Selectable>? selection,
) {
  if (selection == null || selection.isEmpty) return [];
  final identifiers = selection.map((item) => item.id).toList();
  if (identifiers.any((id) => id is! AuthoringResourceIdentifier)) {
    return availableSelectionOperations(
      SelectionOperationsRoot.of(context),
      selection,
    );
  }
  final resources = identifiers.cast<AuthoringResourceIdentifier>();
  final scope = resources.first.scope;
  if (resources.any((id) => id.scope != scope)) return [];
  return resourceSelectionOperationsFor(
    ref,
    scope,
    resources.map((id) => id.resourceId),
  );
}

List<SelectionOperation> resourceSelectionOperationsFor(
  WidgetRef ref,
  AuthoringScope scope,
  Iterable<skir.ResourceId> targets,
) {
  final observed = ref.watch(workingAuthoringDocumentProvider(scope));
  final document = observed.value;
  if (document == null) return [];
  final invocation = captureResourceOperationInvocation(
    document: document,
    targets: targets,
    invocationId: skir.InvocationId(value: "operation-resolution"),
  );
  final resolved = ref.watch(resourceOperationsProvider(scope, invocation));
  if (resolved.isLoading) {
    return const [_UnavailableResourceOperation("Loading operations")];
  }
  if (resolved.hasError) {
    return const [
      _UnavailableResourceOperation("Resource operations unavailable"),
    ];
  }
  final operations = resolved.requireValue;
  return [
    for (final operation in operations.operations)
      if (operation.availability != skir.OperationAvailability.hidden)
        ResourceSelectionOperation.create(
          scope: scope,
          invocation: invocation,
          operation: operation,
          primary: operation.definition.id == operations.primaryOperation,
          canMutate: ResourceOperationSurface.maybeOf(ref.context)?.canMutate,
        ),
  ];
}

/// Carries immutable targets into menus, inspector controls and shortcuts.
class ResourceSelectionOperation extends SelectionOperation {
  const ResourceSelectionOperation({
    required this.scope,
    required this.invocation,
    required this.operation,
    this.canMutate,
  });

  factory ResourceSelectionOperation.create({
    required AuthoringScope scope,
    required skir.OperationInvocation invocation,
    required skir.ResolvedResourceOperation operation,
    required bool primary,
    bool Function()? canMutate,
  }) {
    final intent = primary
        ? PrimaryActionIntent
        : operation.definition.id == resourceDeleteOperationId
        ? DeleteIntent
        : null;
    return intent == null
        ? ResourceSelectionOperation(
            scope: scope,
            invocation: invocation,
            operation: operation,
            canMutate: canMutate,
          )
        : _ShortcutResourceSelectionOperation(
            scope: scope,
            invocation: invocation,
            operation: operation,
            canMutate: canMutate,
            intent: intent,
          );
  }

  final AuthoringScope scope;
  final skir.OperationInvocation invocation;
  final skir.ResolvedResourceOperation operation;
  final bool Function()? canMutate;
  bool get enabled =>
      operation.availability == skir.OperationAvailability.enabled &&
      (operation.definition.action is skir.EditorAction_navigateWrapper ||
          (canMutate?.call() ?? true));
  String? get disabledReason =>
      operation.definition.action is! skir.EditorAction_navigateWrapper &&
          !(canMutate?.call() ?? true)
      ? "This view is read only"
      : switch (operation.availability) {
          skir.OperationAvailability_disabledWrapper(:final value) => value,
          _ => null,
        };
  @override
  String get name => operation.definition.presentation.label;
  @override
  String get description => operation.definition.presentation.description;
  @override
  bool canExecuteOn(List<Selectable> selection) => true;

  @override
  Future<void> executeOn(WidgetRef ref, {skir.DataValue? initialInput}) async {
    if (!enabled || !ref.context.mounted) return;
    final workspace = ref.read(realmEditingProvider(scope));
    final captured = skir.OperationInvocation(
      invocationId: skir.InvocationId(value: const Uuid().v4()),
      catalog: invocation.catalog,
      targets: invocation.targets,
      origin: invocation.origin,
    );
    final runner = ResourceOperationRunner(
      ref: ref,
      context: ref.context,
      scope: scope,
      workspace: workspace,
      commands: ref.read(authoredResourceCommandsProvider(scope)),
      invocation: captured,
      label: name,
      declaredConfirmation: operation.definition.presentation.confirmation,
      canMutate: canMutate,
    );
    try {
      await ResourceActionDispatcher(
        catalog: workspace.document.catalog,
        context: resourceActionContext(workspace.document, captured.targets),
        isCurrent: () => runner.isCurrent,
        navigate: runner.navigate,
        invokeCommand: runner.invokeCommand,
        reload: runner.reload,
        prepare: (capability, targets, seeded) =>
            runner.prepare(capability, targets, initialInput ?? seeded),
      ).dispatch(operation.definition.action);
    } finally {
      runner.dispose();
    }
  }

  @override
  MenuItem menuItem(WidgetRef ref) => MenuItem(
    label: disabledReason == null ? name : "$name ($disabledReason)",
    icon: operation.definition.presentation.icon.isEmpty
        ? null
        : Icones(operation.definition.presentation.icon),
    color:
        operation.definition.presentation.tone ==
            skir.HeaderActionTone.destructive
        ? Theme.of(ref.context).colorScheme.error
        : null,
    onPressed: enabled ? () => executeOn(ref) : null,
  );

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => ResourceOperationButton(
      label: name,
      description: description,
      disabledReason: disabledReason,
      onInvoke: enabled ? () => executeOn(ref) : null,
    ),
  );
}

final class _ShortcutResourceSelectionOperation
    extends ResourceSelectionOperation
    implements ShortcutableOperation {
  const _ShortcutResourceSelectionOperation({
    required super.scope,
    required super.invocation,
    required super.operation,
    required this.intent,
    super.canMutate,
  });
  final Type intent;
  @override
  ActionShortcut get shortcut => ActionShortcut.intent(
    id: "resource_operation_${operation.definition.id.local}",
    label: name,
    description: description,
    intent: intent,
    priority: 10,
    onInvoke: enabled ? executeOn : (_) {},
  );
}

final class _UnavailableResourceOperation extends SelectionOperation {
  const _UnavailableResourceOperation(this.name);
  @override
  final String name;
  @override
  String get description => name;
  @override
  bool canExecuteOn(List<Selectable> selection) => true;
  @override
  void executeOn(WidgetRef ref) {}
  @override
  MenuItem menuItem(WidgetRef ref) => MenuItem(label: name);
  @override
  Widget inspectorButton(List<Selectable> selection) => Text(name);
}

/// Supplies the reserved action context without reading global selection.
PortableInvocationContext resourceActionContext(
  AuthoringDocument document,
  Iterable<skir.ResourceId> resources,
) {
  final ids = resources.toList(growable: false);
  return PortableInvocationContext(
    catalogGeneration: document.generation,
    queries: PortableExpressionQueries(
      catalog: document.catalog,
      authored: document,
    ),
    bindings: {
      skir.ExpressionBindingId(
        value: "context:selection",
      ): PortableExpressionBinding(
        value: skir.DataValue.createListValue(
          items: [
            for (final (index, id) in ids.indexed)
              skir.ListItem(
                id: skir.ItemId(value: "selection:$index"),
                value: skir.DataValue.wrapStringValue(id.value),
              ),
          ],
        ),
      ),
      if (ids.length == 1)
        skir.ExpressionBindingId(
          value: "context:subject",
        ): PortableExpressionBinding(
          value: skir.DataValue.wrapStringValue(ids.single.value),
        ),
    },
  );
}

/// Invokes a primary affordance with the resource captured by the gesture.
Future<void> invokeResourcePrimary(
  WidgetRef ref,
  AuthoringResourceIdentifier resource,
) async {
  final commandsLease = ref.listenManual(
    authoredResourceCommandsProvider(resource.scope),
    (_, _) {},
  );
  try {
    final workspace = ref.read(realmEditingProvider(resource.scope));
    final router = ref.read(appRouterProvider);
    final navigationRevision = router.navigationRevision;
    final invocation = captureResourceOperationInvocation(
      document: workspace.document,
      targets: [resource.resourceId],
    );
    final result = await ref
        .read(authoredResourceCommandsProvider(resource.scope))
        .resolveResourceOperations(
          skir.ResolveResourceOperationsRequest(
            invocation: invocation,
            context: workspace.captureOperationContext().context,
          ),
        );
    if (!ref.context.mounted ||
        router.navigationRevision != navigationRevision ||
        ref.read(selectedAuthoringScopeProvider) != resource.scope) {
      return;
    }
    if (result case skir.ResolveResourceOperationsResult_resolvedWrapper(
      :final value,
    )) {
      final primary = value.operations
          .where((item) => item.definition.id == value.primaryOperation)
          .firstOrNull;
      if (primary == null) return;
      await ResourceSelectionOperation.create(
        scope: resource.scope,
        invocation: invocation,
        operation: primary,
        primary: true,
      ).executeOn(ref);
    }
  } finally {
    commandsLease.close();
  }
}

/// Supplies the invoking view's current mutation access across async prompts.
class ResourceOperationSurface extends InheritedWidget {
  const ResourceOperationSurface({
    required this.canMutate,
    required super.child,
    super.key,
  });
  final bool Function() canMutate;
  static ResourceOperationSurface? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ResourceOperationSurface>();
  @override
  bool updateShouldNotify(ResourceOperationSurface oldWidget) =>
      canMutate != oldWidget.canMutate;
}

/// Supplies gesture values to a declared action without creating another mutator.
Future<void> invokeResourceDropOperation({
  required WidgetRef ref,
  required AuthoringScope scope,
  required AuthoringResourceDragGroup group,
  required String operationLocalId,
  required Map<String, skir.DataValue> suppliedFields,
  required bool Function() isCurrent,
}) async {
  final commandsLease = ref.listenManual(
    authoredResourceCommandsProvider(scope),
    (_, _) {},
  );
  try {
    if (!isCurrent()) return;
    final router = ref.read(appRouterProvider);
    final navigationRevision = router.navigationRevision;
    final workspace = ref.read(realmEditingProvider(scope));
    final commands = ref.read(authoredResourceCommandsProvider(scope));
    final invocation = captureResourceOperationInvocation(
      document: workspace.document,
      targets: group.memberships.keys.map((item) => item.resourceId),
      origin: skir.OperationOrigin(
        container:
            group.memberships.values
                    .map((item) => item.source)
                    .toSet()
                    .length ==
                1
            ? group.memberships.values.first.source
            : null,
        occurrences: group.memberships.values,
      ),
    );
    final resolved = await commands.resolveResourceOperations(
      skir.ResolveResourceOperationsRequest(
        invocation: invocation,
        context: workspace.captureOperationContext().context,
      ),
    );
    if (!ref.context.mounted ||
        !isCurrent() ||
        router.navigationRevision != navigationRevision) {
      return;
    }
    if (resolved is! skir.ResolveResourceOperationsResult_resolvedWrapper) {
      throw StateError("The resource drop operation is unavailable");
    }
    final id = (resourceDeleteOperationId.toMutable()..local = operationLocalId)
        .toFrozen();
    final operation = resolved.value.operations
        .where((item) => item.definition.id == id)
        .firstOrNull;
    if (operation == null ||
        operation.availability != skir.OperationAvailability.enabled) {
      return;
    }
    final action = operation.definition.action;
    if (action is! skir.EditorAction_authoringWrapper) {
      throw StateError("The drop action does not prepare an authored edit");
    }
    final input = workspace.document.catalog.snapshot.capabilities
        .whereType<skir.CapabilityDefinition_authoringWrapper>()
        .map((item) => item.value)
        .where((item) => item.capabilityId == action.value.capability)
        .firstOrNull
        ?.input;
    if (input == null) {
      throw StateError("The drop action has no declared input");
    }
    final value = seedResourceOperationInput(
      workspace.document,
      input,
      suppliedFields,
    );
    await ResourceSelectionOperation.create(
      scope: scope,
      invocation: invocation,
      operation: operation,
      primary: false,
      canMutate: () => isCurrent() && (group.sourceCanMutate?.call() ?? true),
    ).executeOn(ref, initialInput: value);
  } finally {
    commandsLease.close();
  }
}

skir.DataValue seedResourceOperationInput(
  AuthoringDocument document,
  skir.OperationInputDefinition definition,
  Map<String, skir.DataValue> supplied,
) {
  final actual = document.catalog.namedUse(definition.type);
  if (actual == null) {
    throw StateError("The operation input is not a named record");
  }
  final fields = document.catalog.fields(
    skir.TypeSelection.wrapComplete(actual),
  );
  if (supplied.keys.any(
    (key) => !fields.any((field) => field.template.key == key),
  )) {
    throw StateError("The gesture supplied an unknown operation input field");
  }
  return skir.DataValue.createNamed(
    actualType: actual,
    payload: skir.DataValue.createRecord(
      fields: [
        for (final field in fields)
          skir.FieldValue(
            name: field.template.key,
            value: supplied.containsKey(field.template.key)
                ? document
                      .defaultValue(field.type)
                      .withAuthoredPayload(supplied[field.template.key]!)
                : document.defaultValue(field.type),
          ),
      ],
    ),
  );
}

/// Hover checks share preparation with activation and never stage their result.
@riverpod
Future<bool> resourceDropAvailable(
  Ref ref,
  AuthoringScope scope,
  skir.OperationInvocation invocation,
  String operationLocalId,
  skir.DataValue supplied,
) async {
  ref.watch(workingAuthoringDocumentProvider(scope));
  final workspace = ref.read(realmEditingProvider(scope));
  final commands = ref.watch(authoredResourceCommandsProvider(scope));
  final capture = workspace.captureOperationContext();
  final resolved = await commands.resolveResourceOperations(
    skir.ResolveResourceOperationsRequest(
      invocation: invocation,
      context: capture.context,
    ),
  );
  if (!ref.mounted) return false;
  if (resolved is! skir.ResolveResourceOperationsResult_resolvedWrapper) {
    return false;
  }
  final id = (resourceDeleteOperationId.toMutable()..local = operationLocalId)
      .toFrozen();
  final operation = resolved.value.operations
      .where((item) => item.definition.id == id)
      .firstOrNull;
  if (operation == null ||
      operation.availability != skir.OperationAvailability.enabled) {
    return false;
  }
  final action = operation.definition.action;
  if (action is! skir.EditorAction_authoringWrapper) return false;
  final input = capture.document.catalog.snapshot.capabilities
      .whereType<skir.CapabilityDefinition_authoringWrapper>()
      .map((item) => item.value)
      .where((item) => item.capabilityId == action.value.capability)
      .firstOrNull
      ?.input;
  if (input == null) return false;
  final fields = supplied.authoredRecord?.fields;
  if (fields == null) return false;
  final initial = seedResourceOperationInput(capture.document, input, {
    for (final field in fields) field.name: field.value,
  });
  final prepared = await commands.prepareValue(
    skir.ValuePreparationRequest(
      catalog: invocation.catalog,
      target: skir.PreparationTarget.wrapValue(input.type),
      suppliedValue: initial,
    ),
  );
  if (!ref.mounted) return false;
  final normalized = switch (prepared.content) {
    skir.PreparedContent_valueWrapper(:final value) => value,
    _ => throw StateError("Operation input preparation returned a record"),
  };
  final result = await commands.prepareAuthoringAction(
    skir.PrepareAuthoringActionRequest(
      invocation: invocation,
      capability: action.value.capability,
      context: capture.context,
      inputRevision: 0,
      input: normalized,
      choices: const [],
    ),
  );
  return result is skir.AuthoringActionResult_previewWrapper ||
      result is skir.AuthoringActionResult_needsInputWrapper;
}
