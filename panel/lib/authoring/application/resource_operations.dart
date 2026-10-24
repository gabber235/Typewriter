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
      case skir.ResolveResourceOperationsResult_staleObservationErrorWrapper():
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
    if (contract == null || !contract.ownsResources) continue;
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

/// The client navigation entries, then the catalog operations in the order
/// the Realm resolved them: by group, then order.
List<SelectionOperation> resourceSelectionOperationsFor(
  WidgetRef ref,
  AuthoringScope scope,
  Iterable<skir.ResourceId> targets,
) {
  final observed = ref.watch(workingAuthoringDocumentProvider(scope));
  final document = observed.value;
  if (document == null) return [];
  final ids = targets.toSet().toList(growable: false);
  final navigation = [
    if (ids.length == 1) ...[
      ResourceOpenOperation(
        AuthoringResourceIdentifier.inScope(scope, ids.single),
      ),
      ResourceInspectOperation(
        AuthoringResourceIdentifier.inScope(scope, ids.single),
      ),
    ],
  ];
  final invocation = captureResourceOperationInvocation(
    document: document,
    targets: ids,
    invocationId: skir.InvocationId(value: "operation-resolution"),
  );
  final resolved = ref.watch(resourceOperationsProvider(scope, invocation));
  if (resolved.isLoading) {
    return [
      ...navigation,
      const _UnavailableResourceOperation("Loading operations"),
    ];
  }
  if (resolved.hasError) {
    return [
      ...navigation,
      const _UnavailableResourceOperation("Resource operations unavailable"),
    ];
  }
  return [
    ...navigation,
    for (final operation in resolved.requireValue.operations)
      if (operation.availability != skir.OperationAvailability.hidden)
        ResourceSelectionOperation.create(
          scope: scope,
          invocation: invocation,
          operation: operation,
          canMutate: ResourceOperationSurface.maybeOf(ref.context)?.canMutate,
        ),
  ];
}

/// Menu sections of resource affordances, in display order.
enum ResourceOperationMenuGroup { navigation, edit, organize, destructive }

/// Carries immutable targets into menus, inspector controls and shortcuts.
/// Every catalog operation prepares an authored edit through its capability.
class ResourceSelectionOperation extends SelectionOperation {
  const ResourceSelectionOperation({
    required this.scope,
    required this.invocation,
    required this.operation,
    this.canMutate,
  });

  /// Binds the operation's declared shortcut, if any, to its intent.
  factory ResourceSelectionOperation.create({
    required AuthoringScope scope,
    required skir.OperationInvocation invocation,
    required skir.ResolvedResourceOperation operation,
    bool Function()? canMutate,
  }) => switch (operation.definition.presentation.shortcut) {
    skir.OperationShortcut.delete => _ShortcutResourceSelectionOperation(
      scope: scope,
      invocation: invocation,
      operation: operation,
      canMutate: canMutate,
      intent: DeleteIntent,
    ),
    _ => ResourceSelectionOperation(
      scope: scope,
      invocation: invocation,
      operation: operation,
      canMutate: canMutate,
    ),
  };

  final AuthoringScope scope;
  final skir.OperationInvocation invocation;
  final skir.ResolvedResourceOperation operation;
  final bool Function()? canMutate;
  bool get enabled =>
      operation.availability == skir.OperationAvailability.enabled &&
      (canMutate?.call() ?? true);
  String? get disabledReason => !(canMutate?.call() ?? true)
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
  bool get showInInspector =>
      operation.definition.presentation.inspector !=
      skir.OperationInspector.hidden;
  @override
  Object get menuGroup => switch (operation.definition.presentation.group) {
    skir.OperationGroup.organize => ResourceOperationMenuGroup.organize,
    skir.OperationGroup.destructive => ResourceOperationMenuGroup.destructive,
    _ => ResourceOperationMenuGroup.edit,
  };
  @override
  bool canExecuteOn(List<Selectable> selection) => true;

  /// Prepares the operation for the captured targets. [initialInput] seeds
  /// the input, as a drop does with the resource dropped onto; the input form
  /// opens only when the Realm needs more.
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
      canMutate: canMutate,
    );
    try {
      await runner.prepare(
        operation.definition.capability,
        captured.targets.toList(growable: false),
        initialInput,
      );
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
      presentation: operation.definition.presentation,
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
    id: "resource_operation_${operation.definition.id.declaration}",
    label: name,
    description: description,
    intent: intent,
    priority: 10,
    onInvoke: enabled ? executeOn : (_) {},
  );
}

/// Opens the nearest surface of one resource through the SurfaceNavigator,
/// like activating it in a navigator. Bound to the primary action intent.
final class ResourceOpenOperation extends IntentShortcutOperation {
  const ResourceOpenOperation(this.resource);

  final AuthoringResourceIdentifier resource;

  @override
  String get name => "Open";
  @override
  String get description => "Open the resource where it is laid out";
  @override
  Type get intent => PrimaryActionIntent;
  @override
  Object get menuGroup => ResourceOperationMenuGroup.navigation;
  @override
  bool canExecuteOn(List<Selectable> selection) => true;
  @override
  Future<void> executeOn(WidgetRef ref) => openAuthoredResource(ref, resource);
  @override
  MenuItem menuItem(WidgetRef ref) => MenuItem(
    label: name,
    icon: const Icon(Icons.open_in_new),
    onPressed: () => executeOn(ref),
  );
  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) => Tooltip(
      message: description,
      child: TextButton.icon(
        onPressed: () => executeOn(ref),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(name),
      ),
    ),
  );
}

/// Selects one resource and reveals its inspector without leaving the
/// current surface. Menus only: the inspector already shows it.
final class ResourceInspectOperation extends SelectionOperation {
  const ResourceInspectOperation(this.resource);

  final AuthoringResourceIdentifier resource;

  @override
  String get name => "Inspect";
  @override
  String get description => "Show the resource in the inspector";
  @override
  bool get showInInspector => false;
  @override
  Object get menuGroup => ResourceOperationMenuGroup.navigation;
  @override
  bool canExecuteOn(List<Selectable> selection) => true;
  @override
  Future<void> executeOn(WidgetRef ref) => ref
      .read(realmSurfaceNavigationProvider)
      .navigate(
        resource.scope,
        resource.resourceId,
        skir.ResourceNavigationMode.edit,
        isCurrent: () => ref.context.mounted,
      );
  @override
  MenuItem menuItem(WidgetRef ref) => MenuItem(
    label: name,
    icon: const Icon(Icons.info_outline),
    onPressed: () => executeOn(ref),
  );
  @override
  Widget inspectorButton(List<Selectable> selection) => const SizedBox.shrink();
}

/// Opens the nearest surface of [resource], as the Open entry does.
Future<void> openAuthoredResource(
  WidgetRef ref,
  AuthoringResourceIdentifier resource,
) async {
  await ref
      .read(realmSurfaceNavigationProvider)
      .open(resource.scope, resource.resourceId);
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
