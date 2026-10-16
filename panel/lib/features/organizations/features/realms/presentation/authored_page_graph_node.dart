import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Installs authored resource interactions at the portable page boundary.
class AuthoredPageInteractions extends StatelessWidget {
  const AuthoredPageInteractions({
    required this.authoringScope,
    required this.binding,
    required this.child,
    this.prepareValue,
    super.key,
  });

  final AuthoringScope authoringScope;
  final RealmEditingBinding? binding;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;
  final Widget child;

  @override
  Widget build(BuildContext context) => PortablePageInteractionScope(
    graphBuilder: (context, entries, scope, graph) => _AuthoredPageGraph(
      authoringScope: authoringScope,
      binding: binding,
      entries: entries,
      pageScope: scope,
      prepareValue: prepareValue,
      child: graph,
    ),
    nodeBuilder: (context, entry, scope, content) {
      final page = _AuthoredPageGraphScope.of(context);
      if (page == null) return content;
      return AuthoredPageGraphNode(
        identifier: AuthoringResourceIdentifier.inScope(
          authoringScope,
          entry.resource,
        ),
        page: page,
        child: content,
      );
    },
    child: child,
  );
}

class _AuthoredPageGraph extends ConsumerStatefulWidget {
  const _AuthoredPageGraph({
    required this.authoringScope,
    required this.binding,
    required this.entries,
    required this.pageScope,
    required this.child,
    this.prepareValue,
  });

  final AuthoringScope authoringScope;
  final RealmEditingBinding? binding;
  final List<PortablePageEntryProjection> entries;
  final PortablePresentationScope pageScope;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;
  final Widget child;

  @override
  ConsumerState<_AuthoredPageGraph> createState() => _AuthoredPageGraphState();
}

class _AuthoredPageGraphState extends ConsumerState<_AuthoredPageGraph> {
  bool get canMutate =>
      mounted &&
      widget.pageScope.enabled &&
      !widget.pageScope.readOnly &&
      widget.binding != null &&
      !widget.binding!.blocked;

  @override
  Widget build(BuildContext context) {
    final expectedBinding = widget.binding;
    final expectedResource = widget.pageScope.resource;
    final expectedScope = widget.authoringScope;
    final page = AuthoredPageGraphContext(
      authoringScope: widget.authoringScope,
      entries: widget.entries,
      binding: widget.binding,
      pageScope: widget.pageScope,
      prepareValue: widget.prepareValue,
      canMutate: () =>
          canMutate &&
          identical(widget.binding, expectedBinding) &&
          widget.pageScope.resource == expectedResource &&
          widget.authoringScope == expectedScope,
    );
    final existing = SelectionOperationsRoot.of(context);
    return _AuthoredPageGraphScope(
      page: page,
      child: SelectionOperationsRoot(
        operations: [
          for (final operation in existing)
            if (canMutate ||
                operation is! DeleteOperation && operation is! UnbindOperation)
              if (operation is DeleteOperation)
                DeleteOperation(canMutate: page.canMutate)
              else
                operation,
          if (canMutate)
            for (final kind in _PageOperationKind.values)
              _PageResourceOperation(page, kind),
        ],
        child: Actions(
          actions: {
            if (!canMutate)
              DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (_) => null),
          },
          child: SelectionOperationShortcuts(child: widget.child),
        ),
      ),
    );
  }
}

class _AuthoredPageGraphScope extends InheritedWidget {
  const _AuthoredPageGraphScope({required this.page, required super.child});
  final AuthoredPageGraphContext page;

  static AuthoredPageGraphContext? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_AuthoredPageGraphScope>()
      ?.page;

  @override
  bool updateShouldNotify(_AuthoredPageGraphScope oldWidget) =>
      page != oldWidget.page;
}

/// The current page observation and the commands shared by its input paths.
class AuthoredPageGraphContext {
  const AuthoredPageGraphContext({
    required this.authoringScope,
    required this.entries,
    required this.binding,
    required this.pageScope,
    required this.canMutate,
    this.prepareValue,
  });

  final AuthoringScope authoringScope;
  final List<PortablePageEntryProjection> entries;
  final RealmEditingBinding? binding;
  final PortablePresentationScope pageScope;
  final bool Function() canMutate;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;

  AuthoredResourceLinkCommands get links => AuthoredResourceLinkCommands(
    workspace: binding!.workspace,
    scope: authoringScope,
    canMutate: canMutate,
    prepareValue: prepareValue,
  );

  AuthoredPageResourceCommands get pages => AuthoredPageResourceCommands(
    workspace: binding!.workspace,
    scope: authoringScope,
    canMutate: canMutate,
    prepareValue: prepareValue,
  );

  AuthoringResourceDragGroup group(
    AuthoringResourceIdentifier primary,
    Iterable<SelectableIdentifier> selection,
  ) => AuthoringResourceDragGroup.forSelection(
    primary: primary,
    entries: entries,
    selection: selection,
    sourceCanMutate: canMutate,
  );

  Future<void> link(
    BuildContext context,
    AuthoringResourceDragGroup group,
    skir.ResourceId target,
  ) async {
    if (!canMutate()) return;
    final command = links;
    final plan = command.plan(group, target);
    if (plan.slots.isEmpty) {
      pageScope.reportStatus?.call(plan.problem ?? "These entries cannot link");
      return;
    }
    final slot = plan.slots.length == 1
        ? plan.slots.single
        : await _choosePageOption(context, "Choose source field", {
            for (final slot in plan.slots) slot: slot.label,
          });
    if (slot == null || !context.mounted || !canMutate()) return;
    final choices = await _chooseCounterparts(context, slot, canMutate);
    if (choices == null || !context.mounted || !canMutate()) return;
    final mixed =
        choices.values.any((choice) => choice.disconnect != null) &&
        choices.values.any((choice) => choice.disconnect == null);
    if (mixed) {
      final confirmed = await showConfirmationDialogue(
        context: context,
        title: "Change these links?",
        content: "This drop adds links for some entries and removes existing links for others.",
        confirmText: "Change links",
      );
      if (!confirmed || !context.mounted || !canMutate()) return;
    }
    final result = await command.apply(
      group,
      slot,
      choices,
      confirmedMixed: mixed,
      isCurrent: () => context.mounted && canMutate(),
    );
    if (context.mounted) result.report(context);
  }
}

/// Supplies selection, portable visual state and authored node drag routing.
class AuthoredPageGraphNode extends HookConsumerWidget {
  const AuthoredPageGraphNode({
    required this.identifier,
    required this.page,
    required this.child,
    super.key,
  });

  final AuthoringResourceIdentifier identifier;
  final AuthoredPageGraphContext page;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final drag = GraphDrag.maybeOf(context);
    useListenable(drag?.draggingInsideGraph);
    final selection = ref.watch(selectionProvider);
    final group = page.group(identifier, selection);
    final editable = page.canMutate();
    final mode = ref.watch(currentInteractionModeProvider);
    final directionalMode =
        editable && (mode is GraphMoveMode || mode is GraphResizeMode)
        ? mode as DirectionalInteractionMode
        : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final themes = InheritedTheme.capture(
          from: context,
          to: Overlay.of(context, rootOverlay: true).context,
        );
        final providers = ProviderScope.containerOf(context);
        return Selector(
          selectableId: identifier,
          focusNode: focus,
          shortcuts: {
            if (directionalMode != null)
              for (final entry in movementShortcuts.entries)
                for (final key in entry.key)
                  SingleActivator(key): directionalMode.intentForDirection(
                    entry.value,
                  ),
          },
          builder: (selected, focused, hovered) {
            Widget content({bool drop = false}) => PresentationInteractionScope(
              value: PresentationInteraction(
                selected: selected || drop,
                focused: focused,
                hovered: hovered || drop,
                disabled: !page.pageScope.enabled,
                readOnly: !editable,
              ),
              child: child,
            );
            final target = GraphDragTargetRegion(
              targetId: identifier.graphId,
              child: DragTarget<AuthoringResourceDragGroup>(
                onWillAcceptWithDetails: (details) =>
                    page.canMutate() &&
                    page.links
                        .plan(details.data, identifier.resourceId)
                        .slots
                        .isNotEmpty,
                onAcceptWithDetails: (details) => unawaited(
                  page.link(context, details.data, identifier.resourceId),
                ),
                builder: (context, accepted, rejected) {
                  final dropLabel = accepted.isEmpty
                      ? null
                      : _referenceDropLabel(
                          page.links.plan(
                            accepted.first!,
                            identifier.resourceId,
                          ),
                        );
                  return Semantics(
                    label: dropLabel,
                    selected: selected,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        content(drop: accepted.isNotEmpty),
                        if (dropLabel != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                                child: Text(
                                  dropLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onInverseSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (rejected.isNotEmpty)
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                  width: 2,
                                ),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
            if (!editable) return target;
            return Draggable<AuthoringResourceDragGroup>(
              data: group,
              rootOverlay: true,
              onDragStarted: () => drag?.beginDrag(group),
              onDragEnd: (_) => drag?.endDrag(),
              onDraggableCanceled: (_, _) => drag?.endDrag(),
              onDragCompleted: () => drag?.endDrag(),
              feedback: HookBuilder(
                builder: (context) {
                  useListenable(drag?.draggingInsideGraph);
                  if (drag?.draggingInsideGraph.value ?? false) {
                    return const SizedBox.shrink();
                  }
                  return themes.wrap(
                    UncontrolledProviderScope(
                      container: providers,
                      child: PortableDiagnosticPreview(
                        operations: page.pageScope.operations,
                        child: ExcludeFocus(
                          child: Material(
                            type: MaterialType.transparency,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: content(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              childWhenDragging: Opacity(opacity: .45, child: target),
              child: target,
            );
          },
        );
      },
    );
  }
}

String _referenceDropLabel(AuthoredResourceLinkPlan plan) {
  if (plan.slots.length != 1) return "Choose link field";
  final choices = plan.slots.single.members.expand((member) => member.choices);
  final links = choices.any((choice) => choice.disconnect == null);
  final unlinks = choices.any((choice) => choice.disconnect != null);
  if (links && unlinks) return "Add and remove links";
  return unlinks ? "Unlink" : "Link";
}

enum _PageOperationKind { link, move, disconnect }

class _PageResourceOperation extends SelectionOperation {
  const _PageResourceOperation(this.page, this.kind);
  final AuthoredPageGraphContext page;
  final _PageOperationKind kind;

  @override
  String get name => switch (kind) {
    _PageOperationKind.link => "Link with",
    _PageOperationKind.move => "Move to page",
    _PageOperationKind.disconnect => "Disconnect from page",
  };

  @override
  String get description => name;

  @override
  bool canExecuteOn(List<Selectable> selection) =>
      page.canMutate() &&
      selection.isNotEmpty &&
      selection.every(
        (item) =>
            item.id is AuthoringResourceIdentifier &&
            (item.id as AuthoringResourceIdentifier).scope ==
                page.authoringScope &&
            page.entries.any(
              (entry) =>
                  entry.resource ==
                  (item.id as AuthoringResourceIdentifier).resourceId,
            ),
      );

  @override
  Future<void> executeOn(WidgetRef ref) async {
    final selection = ref.read(selectedProvider).value;
    if (selection == null || !canExecuteOn(selection)) return;
    final group = page.group(
      selection.first.id as AuthoringResourceIdentifier,
      selection.map((item) => item.id),
    );
    final context = ref.context;
    final selectionOwner = ref.read(selectionProvider.notifier);
    if (kind == _PageOperationKind.disconnect) {
      final result = await page.pages.disconnect(
        group,
        isCurrent: () => context.mounted && page.canMutate(),
      );
      if (context.mounted) result.report(context);
      return;
    }
    final workspace = page.binding!.workspace;
    final options = <skir.ResourceId, String>{};
    for (final entry in workspace.document.resources.entries) {
      final valid = kind == _PageOperationKind.link
          ? page.links.plan(group, entry.key).slots.isNotEmpty
          : page.pages.plan(group, entry.key) == null;
      if (!valid) continue;
      options[entry.key] =
          entry.value.authoredField("name")?.authoredString ?? entry.key.value;
    }
    final target = await _choosePageOption(context, name, options);
    if (target == null || !context.mounted || !page.canMutate()) return;
    if (kind == _PageOperationKind.link) {
      await page.link(context, group, target);
    } else {
      final result = await moveAuthoredResourcesToPage(
        context: context,
        command: page.pages,
        group: group,
        destination: target,
        isCurrent: () => context.mounted && page.canMutate(),
      );
      if (result is EditStaged) {
        selectionOwner.unselectAll(group.memberships.keys.toList());
      }
      if (!context.mounted) return;
      result.report(context);
      if (result is EditStaged) {
        FocusScope.of(context).requestFocus();
      }
    }
  }

  @override
  MenuItem menuItem(WidgetRef ref) =>
      MenuItem(label: name, onPressed: () => executeOn(ref));

  @override
  Widget inspectorButton(List<Selectable> selection) => Consumer(
    builder: (context, ref, _) =>
        TextButton(onPressed: () => executeOn(ref), child: Text(name)),
  );
}

/// Resolves destination occurrences before transferring the complete group.
Future<EditStageResult> moveAuthoredResourcesToPage({
  required BuildContext context,
  required AuthoredPageResourceCommands command,
  required AuthoringResourceDragGroup group,
  required skir.ResourceId destination,
  required bool Function() isCurrent,
}) async {
  if (!isCurrent()) return const EditStageResult.unchanged();
  final plan = command.planChoices(group, destination);
  if (plan.problem case final problem?) {
    return EditStageResult.rejected(problem, null);
  }
  if (plan.slots.isEmpty) return const EditStageResult.unchanged();
  final choices = await _chooseCounterparts(
    context,
    plan.slots.single,
    isCurrent,
  );
  if (choices == null || !context.mounted || !isCurrent()) {
    return const EditStageResult.unchanged();
  }
  return command.move(
    group,
    destination,
    plannedSlot: plan.slots.single,
    choices: choices,
    isCurrent: isCurrent,
  );
}

Future<Map<skir.ResourceId, AuthoredResourceLinkChoice>?> _chooseCounterparts(
  BuildContext context,
  AuthoredResourceLinkSlot slot,
  bool Function() isCurrent,
) async {
  final choices = <skir.ResourceId, AuthoredResourceLinkChoice>{};
  for (final member in slot.members) {
    final choice = member.choices.length == 1
        ? member.choices.single
        : await _choosePageOption(
            context,
            "Choose counterpart for ${member.resource.value}",
            {for (final choice in member.choices) choice: choice.label},
          );
    if (choice == null || !context.mounted || !isCurrent()) return null;
    choices[member.resource] = choice;
  }
  return choices;
}

Future<T?> _choosePageOption<T>(
  BuildContext context,
  String title,
  Map<T, String> options,
) => showAdvancedDialog<T>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 360,
      child: options.isEmpty
          ? const Text("No compatible resources are available")
          : ListView(
              shrinkWrap: true,
              children: [
                for (final option in options.entries)
                  ListTile(
                    title: Text(option.value),
                    onTap: () => Navigator.of(context).pop(option.key),
                  ),
              ],
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Cancel"),
      ),
    ],
  ),
);
