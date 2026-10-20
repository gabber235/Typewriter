import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Installs authored resource interactions at the portable resources
/// boundary: selection and opening for every layout, one [ResourceDrag] from
/// every member, and drop targets on members, tree group headers, graph
/// canvases and link field controls.
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
      return switch (view.layout) {
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
    },
    groupBuilder: (context, view, group, header) {
      final resources = _AuthoredResourcesScope.of(context);
      if (resources == null) return header;
      return AuthoredResourceGroupHeader(
        resources: resources,
        group: group,
        child: header,
      );
    },
    canvasBuilder: (context, view, toGrid, canvas) {
      final resources = _AuthoredResourcesScope.of(context);
      final location = view.location;
      if (resources == null || location == null) return canvas;
      return ResourceDropTarget(
        scope: authoringScope,
        canMutate: resources.canMutate,
        // A foreign resource is linked into the field and placed at the
        // pointer; a resource owned elsewhere moves to the canvas owner.
        destinations: (pointer) {
          final anchor = toGrid(pointer);
          return [
            DropDestination.linkField(location, anchor: anchor),
            DropDestination.resource(location.resource, anchor: anchor),
          ];
        },
        builder: (context, hover) =>
            ResourceDropHighlight(hover: hover, child: canvas),
      );
    },
    linkFieldBuilder: (context, location, control) => ResourceDropTarget.at(
      scope: authoringScope,
      destination: DropDestination.linkField(location),
      canMutate: () =>
          binding != null &&
          !binding!.blocked &&
          binding!.workspace.state.available,
      builder: (context, hover) =>
          ResourceDropHighlight(hover: hover, child: control),
    ),
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

/// One resources layout and the commands shared by its input paths.
class AuthoredResourcesContext {
  const AuthoredResourcesContext({
    required this.authoringScope,
    required this.binding,
    required this.scope,
    required this.canMutate,
    this.prepareValue,
  });

  final AuthoringScope authoringScope;
  final RealmEditingBinding? binding;
  final PortablePresentationScope scope;
  final bool Function() canMutate;
  final Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  prepareValue;

  bool isRouted(AuthoringResourceIdentifier identifier) =>
      identifier.resourceId == scope.routedResource;

  void open(AuthoringResourceIdentifier identifier) =>
      scope.openResource?.call(identifier.resourceId);
}

/// Drag and drop for one member: it drags itself, with the selection when it
/// is selected, and receives drops onto itself. [builder] styles the member
/// for the drop hover; an accepted hover also shows its hint.
class _ResourceItemDragAndDrop extends ConsumerWidget {
  const _ResourceItemDragAndDrop({
    required this.identifier,
    required this.resources,
    required this.builder,
    this.feedback,
    this.region = false,
  });

  final AuthoringResourceIdentifier identifier;
  final AuthoredResourcesContext resources;
  final Widget Function(BuildContext context, ResourceDropHover hover) builder;
  final WidgetBuilder? feedback;

  /// Marks the target as a graph node region, so the graph's own move target
  /// leaves drops onto this node to it.
  final bool region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drag = ResourceDrag.forSelection(
      primary: identifier,
      selection: ref.watch(selectionProvider),
    );
    final Widget target = ResourceDropTarget.at(
      scope: resources.authoringScope,
      destination: DropDestination.resource(identifier.resourceId),
      canMutate: resources.canMutate,
      builder: (context, hover) => Semantics(
        label: hover.accepted ? hover.hint : null,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            builder(context, hover),
            if (hover.hint case final hint? when hover.accepted)
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: IgnorePointer(child: DropHintChip(hint: hint)),
              ),
          ],
        ),
      ),
    );
    return ResourceDragSource(
      drag: drag,
      enabled: resources.canMutate(),
      feedback: feedback,
      child: region
          ? GraphDragTargetRegion(targetId: identifier.graphId, child: target)
          : target,
    );
  }
}

/// A member of a workspace layout: selected by tap or activation; double tap
/// opens it, like the Open operation.
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
      onDoubleTap: () => openAuthoredResource(ref, identifier),
      builder: (selected, focused, hovered) => _ResourceItemDragAndDrop(
        identifier: identifier,
        resources: resources,
        builder: (context, hover) => PresentationInteractionScope(
          value: PresentationInteraction(
            selected: selected,
            focused: focused,
            hovered: hovered,
            routed: resources.isRouted(identifier),
            disabled: !resources.scope.enabled,
            readOnly: !resources.canMutate(),
            dropAccepted: hover.accepted,
            dropRejected: hover.rejected,
          ),
          child: child,
        ),
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
          child: _ResourceItemDragAndDrop(
            identifier: identifier,
            resources: resources,
            builder: (context, hover) => PresentationInteractionScope(
              value: PresentationInteraction(
                hovered: hovered.value,
                focused: focused.value,
                routed: routed,
                disabled: !resources.scope.enabled,
                dropAccepted: hover.accepted,
                dropRejected: hover.rejected,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A graph member: selection, portable visual state, repositioning through
/// the graph and drops onto the node.
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
    final editable = resources.canMutate();
    final mode = ref.watch(currentInteractionModeProvider);
    final directionalMode =
        editable && (mode is GraphMoveMode || mode is GraphResizeMode)
        ? mode as DirectionalInteractionMode
        : null;
    return LayoutBuilder(
      builder: (context, constraints) => Selector(
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
          Widget content(ResourceDropHover hover) =>
              PresentationInteractionScope(
                value: PresentationInteraction(
                  selected: selected,
                  focused: focused,
                  hovered: hovered,
                  routed: resources.isRouted(identifier),
                  disabled: !resources.scope.enabled,
                  readOnly: !editable,
                  dropAccepted: hover.accepted,
                  dropRejected: hover.rejected,
                ),
                child: child,
              );
          return _ResourceItemDragAndDrop(
            identifier: identifier,
            resources: resources,
            region: true,
            builder: (context, hover) =>
                Semantics(selected: selected, child: content(hover)),
            feedback: (context) => PortableDiagnosticPreview(
              operations: resources.scope.operations,
              child: Material(
                type: MaterialType.transparency,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: content(ResourceDropHover.idle),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A tree group header: dragging it carries every member below it, and a
/// drop moves the dragged resources into this group. Moving members between
/// groups by keyboard is an edit of their grouped field.
class AuthoredResourceGroupHeader extends ConsumerWidget {
  const AuthoredResourceGroupHeader({
    required this.resources,
    required this.group,
    required this.child,
    super.key,
  });

  final AuthoredResourcesContext resources;
  final PortableResourcesGroup group;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ResourceDropTarget.at(
      scope: resources.authoringScope,
      destination: DropDestination.regroup(group.field, group.path),
      canMutate: resources.canMutate,
      builder: (context, hover) =>
          ResourceDropHighlight(hover: hover, child: child),
    );
    final first = group.members.firstOrNull;
    if (first == null) return target;
    final primary = AuthoringResourceIdentifier.inScope(
      resources.authoringScope,
      first.resource,
    );
    return ResourceDragSource(
      drag: ResourceDrag(
        scope: resources.authoringScope,
        primary: primary,
        subjects: [for (final member in group.members) member.resource],
        group: DraggedGroup(field: group.field, path: group.path),
      ),
      enabled: resources.canMutate(),
      feedback: (context) => ResourceDragFeedback(
        label: group.name,
        accent: Theme.of(context).colorScheme.primary,
        count: group.members.length,
      ),
      child: target,
    );
  }
}
