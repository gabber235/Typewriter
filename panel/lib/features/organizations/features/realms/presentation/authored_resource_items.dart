import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Installs authored resource interactions at the portable resources
/// boundary: selection and opening for every layout, graph dragging and
/// linking for graph members, and moving graph members onto pages in trees.
class AuthoredResourcesInteractions extends StatelessWidget {
  const AuthoredResourcesInteractions({
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
  Widget build(BuildContext context) => PortableResourcesInteractionScope(
    layoutBuilder: (context, view, layout) => _AuthoredResourcesLayout(
      authoringScope: authoringScope,
      binding: binding,
      view: view,
      prepareValue: prepareValue,
      child: layout,
    ),
    itemBuilder: (context, view, member, content) {
      final resources = _AuthoredResourcesScope.of(context);
      if (resources == null) return content;
      final identifier = AuthoringResourceIdentifier.inScope(
        authoringScope,
        member.resource,
      );
      final item = switch (view.layout) {
        PortableResourcesLayoutKind.graph => AuthoredGraphItem(
          identifier: identifier,
          resources: resources,
          child: content,
        ),
        _ when view.scope.role == skir.PresentationRole.navigator =>
          AuthoredNavigatorItem(
            identifier: identifier,
            resources: resources,
            label: member.appearance.label,
            child: content,
          ),
        _ => AuthoredResourceItem(
          identifier: identifier,
          resources: resources,
          child: content,
        ),
      };
      // Graph members drag onto the pages a tree lays out.
      return view.layout == PortableResourcesLayoutKind.tree
          ? ResourcePageDropTarget(
              page: member.resource,
              authoringScope: authoringScope,
              child: item,
            )
          : item;
    },
    child: child,
  );
}

class _AuthoredResourcesLayout extends ConsumerStatefulWidget {
  const _AuthoredResourcesLayout({
    required this.authoringScope,
    required this.binding,
    required this.view,
    required this.child,
    this.prepareValue,
  });

  final AuthoringScope authoringScope;
  final RealmEditingBinding? binding;
  final PortableResourcesView view;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;
  final Widget child;

  @override
  ConsumerState<_AuthoredResourcesLayout> createState() =>
      _AuthoredResourcesLayoutState();
}

class _AuthoredResourcesLayoutState
    extends ConsumerState<_AuthoredResourcesLayout> {
  PortablePresentationScope get _scope => widget.view.scope;

  bool get canMutate =>
      mounted &&
      _scope.enabled &&
      !_scope.readOnly &&
      widget.binding != null &&
      !widget.binding!.blocked;

  @override
  Widget build(BuildContext context) {
    final expectedBinding = widget.binding;
    final expectedResource = _scope.resource;
    final expectedScope = widget.authoringScope;
    final resources = AuthoredResourcesContext(
      authoringScope: widget.authoringScope,
      entries: widget.view.members,
      binding: widget.binding,
      scope: _scope,
      prepareValue: widget.prepareValue,
      canMutate: () =>
          canMutate &&
          identical(widget.binding, expectedBinding) &&
          _scope.resource == expectedResource &&
          widget.authoringScope == expectedScope,
    );
    return _AuthoredResourcesScope(
      resources: resources,
      child: ResourceOperationSurface(
        canMutate: resources.canMutate,
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

class _AuthoredResourcesScope extends InheritedWidget {
  const _AuthoredResourcesScope({
    required this.resources,
    required super.child,
  });
  final AuthoredResourcesContext resources;

  static AuthoredResourcesContext? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_AuthoredResourcesScope>()
      ?.resources;

  @override
  bool updateShouldNotify(_AuthoredResourcesScope oldWidget) =>
      resources != oldWidget.resources;
}

/// The current members of one resources layout and the commands shared by
/// their input paths.
class AuthoredResourcesContext {
  const AuthoredResourcesContext({
    required this.authoringScope,
    required this.entries,
    required this.binding,
    required this.scope,
    required this.canMutate,
    this.prepareValue,
  });

  final AuthoringScope authoringScope;
  final List<PortableResourceMember> entries;
  final RealmEditingBinding? binding;
  final PortablePresentationScope scope;
  final bool Function() canMutate;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;

  bool isRouted(AuthoringResourceIdentifier identifier) =>
      identifier.resourceId == scope.routedResource;

  void open(AuthoringResourceIdentifier identifier) =>
      scope.openResource?.call(identifier.resourceId);

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

/// A member of a workspace layout: selected by tap or activation; double tap
/// runs its primary operation, like the primary operation shortcut and the
/// context menu's operations.
class AuthoredResourceItem extends HookConsumerWidget {
  const AuthoredResourceItem({
    required this.identifier,
    required this.resources,
    required this.child,
    super.key,
  });

  final AuthoringResourceIdentifier identifier;
  final AuthoredResourcesContext resources;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    return Selector(
      selectableId: identifier,
      focusNode: focus,
      onDoubleTap: () => invokeResourcePrimary(ref, identifier),
      builder: (selected, focused, hovered) => PresentationInteractionScope(
        value: PresentationInteraction(
          selected: selected,
          focused: focused,
          hovered: hovered,
          routed: resources.isRouted(identifier),
          disabled: !resources.scope.enabled,
          readOnly: !resources.canMutate(),
        ),
        child: child,
      ),
    );
  }
}

/// A member of a navigator: tap or activation opens it, like a sidebar link.
class AuthoredNavigatorItem extends HookWidget {
  const AuthoredNavigatorItem({
    required this.identifier,
    required this.resources,
    required this.label,
    required this.child,
    super.key,
  });

  final AuthoringResourceIdentifier identifier;
  final AuthoredResourcesContext resources;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final focused = useState(false);
    final routed = resources.isRouted(identifier);
    return Semantics(
      button: true,
      selected: routed,
      label: label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => hovered.value = value,
        onShowFocusHighlight: (value) => focused.value = value,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              resources.open(identifier);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => resources.open(identifier),
          child: PresentationInteractionScope(
            value: PresentationInteraction(
              hovered: hovered.value,
              focused: focused.value,
              routed: routed,
              disabled: !resources.scope.enabled,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A graph member: selection, portable visual state and authored node drag
/// routing.
class AuthoredGraphItem extends HookConsumerWidget {
  const AuthoredGraphItem({
    required this.identifier,
    required this.resources,
    required this.child,
    super.key,
  });

  final AuthoringResourceIdentifier identifier;
  final AuthoredResourcesContext resources;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = useFocusNode();
    final selection = ref.watch(selectionProvider);
    final group = resources.group(identifier, selection);
    final dragSource = useGraphDragSource(context, group);
    final offered = dragSource.payload;
    useListenable(dragSource.state);
    useListenable(offered);
    final editable = resources.canMutate();
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
                routed: resources.isRouted(identifier),
                disabled: !resources.scope.enabled,
                readOnly: !editable,
              ),
              child: child,
            );
            final target = GraphDragTargetRegion(
              targetId: identifier.graphId,
              child: ResourceOperationDropTarget(
                scope: resources.authoringScope,
                operationLocalId: "linkWith",
                suppliedFields: {
                  "target": skir.DataValue.wrapStringValue(
                    identifier.resourceId.value,
                  ),
                },
                canMutate: resources.canMutate,
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
                        operations: resources.scope.operations,
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
