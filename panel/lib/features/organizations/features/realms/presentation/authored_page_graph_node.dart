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
    return _AuthoredPageGraphScope(
      page: page,
      child: ResourceOperationSurface(
        canMutate: page.canMutate,
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

  AuthoringResourceDragGroup group(
    AuthoringResourceIdentifier primary,
    Iterable<SelectableIdentifier> selection,
  ) => AuthoringResourceDragGroup.forSelection(
    primary: primary,
    entries: entries,
    selection: selection,
    sourceCanMutate: canMutate,
  );
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
    final selection = ref.watch(selectionProvider);
    final group = page.group(identifier, selection);
    final dragSource = useGraphDragSource(context, group);
    final offered = dragSource.payload;
    useListenable(dragSource.state);
    useListenable(offered);
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
              child: ResourceOperationDropTarget(
                scope: page.authoringScope,
                operationLocalId: "linkWith",
                suppliedFields: {
                  "target": skir.DataValue.wrapStringValue(
                    identifier.resourceId.value,
                  ),
                },
                canMutate: page.canMutate,
                builder: (context, accepted, rejected) {
                  final dropLabel = accepted ? "Link with" : null;
                  return Semantics(
                    label: dropLabel,
                    selected: selected,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        content(drop: accepted),
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
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onInverseSurface,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        if (rejected)
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
            return Draggable<GraphDragPayload<AuthoringResourceDragGroup>>(
              data: offered,
              key: ObjectKey(offered),
              maxSimultaneousDrags: 1,
              dragAnchorStrategy: (widget, context, position) =>
                  dragSource.anchor(offered, widget, context, position),
              rootOverlay: true,
              onDragStarted: () => dragSource.begin(offered),
              onDragUpdate: (details) => dragSource.update(offered, details),
              onDragEnd: (_) => dragSource.end(offered),
              feedback: HookBuilder(
                builder: (context) {
                  useListenable(dragSource.state);
                  useListenable(offered);
                  if (!dragSource.showFeedback(offered)) {
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
