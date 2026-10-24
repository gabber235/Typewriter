part of "../portable_presentation_renderer.dart";

/// Lays out the members of a resources element in its declared layout. Every
/// member renders through its item presentation, or the host chrome when its
/// type declares none. Geometry changes return through the resources host; an
/// application interaction scope can wrap members and layouts without taking
/// over portable presentation policy.
extension _PortableResourcesRendering on PortablePresentationNodeRenderer {
  Widget _renderResources(
    BuildContext context,
    skir.ResourcesElement element,
    PortablePresentationScope childScope,
  ) {
    final host = switch (childScope.host) {
      final PortableResourcesHost value => value,
      _ => null,
    };
    if (host == null) {
      return _diagnostic("The resources binding is unavailable");
    }
    final projection = host.projectResources(
      element.control.binding,
      context: childScope.invocation,
    );
    if (projection.problem case final message?) return _diagnostic(message);
    final members = _orderedMembers(element, projection.members, childScope);
    if (members == null) {
      return _diagnostic("The resources order is unavailable");
    }
    final view = PortableResourcesView(
      members: members,
      scope: childScope,
      location: childScope.location(element.control.binding),
      layout: switch (element.layout) {
        skir.ResourcesLayout_graphWrapper() =>
          PortableResourcesLayoutKind.graph,
        skir.ResourcesLayout_timelineWrapper() =>
          PortableResourcesLayoutKind.timeline,
        skir.ResourcesLayout_gridWrapper() => PortableResourcesLayoutKind.grid,
        skir.ResourcesLayout_treeWrapper() => PortableResourcesLayoutKind.tree,
        _ => PortableResourcesLayoutKind.list,
      },
    );
    final layout = switch (element.layout) {
      skir.ResourcesLayout_graphWrapper(:final value) => _renderResourceGraph(
        context,
        value,
        projection,
        view,
        host,
      ),
      skir.ResourcesLayout_timelineWrapper(:final value) =>
        _renderResourceTimeline(context, value, projection, view, host),
      skir.ResourcesLayout_gridWrapper(:final value) => _renderResourceGrid(
        value,
        view,
      ),
      skir.ResourcesLayout_treeWrapper(:final value) => _ResourceTree(
        layout: value,
        view: view,
      ),
      _ => _ResourceList(view: view),
    };
    return PortableResourcesInteractionScope.maybeOf(context)
            ?.layoutBuilder(context, view, layout) ??
        layout;
  }

  /// Members sorted by the element's order key, keeping link order between
  /// equal keys. Null when a key cannot be evaluated.
  List<PortableResourceMember>? _orderedMembers(
    skir.ResourcesElement element,
    List<PortableResourceMember> members,
    PortablePresentationScope scope,
  ) {
    final order = element.order;
    if (order == null) return members;
    final itemType = scope.catalog?.collectionItemType(
      scope.host?.expectedType(
        element.control.binding,
        context: scope.invocation,
      ),
    );
    final keys = <skir.ResourceId, skir.DataValue?>{};
    for (final member in members) {
      final evaluated = scope
          .copyWith(
            bindings: {
              ...scope.bindings,
              element.itemBindingId: PortableExpressionBinding(
                value: member.link,
                schema: itemType == null
                    ? null
                    : CompletePortablePresentationBinding(itemType),
              ),
            },
          )
          .evaluate(order);
      switch (evaluated) {
        case PortableExpressionAvailable(:final value):
          keys[member.resource] = value;
        case PortableExpressionUnavailable():
          keys[member.resource] = null;
        case PortableExpressionFailed():
          return null;
      }
    }
    final indexed = members.indexed.toList()
      ..sort((left, right) {
        final compared = _compareOrderKeys(
          keys[left.$2.resource],
          keys[right.$2.resource],
        );
        return compared != 0 ? compared : left.$1.compareTo(right.$1);
      });
    return [for (final (_, member) in indexed) member];
  }

  Widget _renderResourceGraph(
    BuildContext context,
    skir.GraphResourcesLayout layout,
    PortableResourcesProjection projection,
    PortableResourcesView view,
    PortableResourcesHost host,
  ) {
    final childScope = view.scope;
    final sides = switch (layout.direction.kind) {
      skir.GraphDirection_kind.rightToLeftConst => (
        EdgeSide.left,
        EdgeSide.right,
      ),
      skir.GraphDirection_kind.topToBottomConst => (
        EdgeSide.bottom,
        EdgeSide.top,
      ),
      skir.GraphDirection_kind.bottomToTopConst => (
        EdgeSide.top,
        EdgeSide.bottom,
      ),
      _ => (EdgeSide.right, EdgeSide.left),
    };
    final appearance = layout.appearance;
    final cellSize = appearance?.cellSize == null
        ? 50.0
        : _number(childScope, appearance!.cellSize);
    if (cellSize == null || !cellSize.isFinite || cellSize <= 0) {
      return _diagnostic("Graph cell size must be finite and positive");
    }
    final edgeColor =
        _color(context, childScope, appearance?.edgeColor) ??
        Theme.of(context).colorScheme.outline;
    final cardPadding = appearance?.cardPadding == null
        ? null
        : _presentationInsets(appearance!.cardPadding);
    final members = view.members;
    final interactions = PortableResourcesInteractionScope.maybeOf(context);
    return Graph(
      canvasBuilder: interactions?.canvasBuilder == null
          ? null
          : (context, toGrid, canvas) =>
                interactions!.canvasBuilder!(context, view, toGrid, canvas),
      data: GraphData(
        cellSize: cellSize,
        elements: [
          for (final (index, member) in members.indexed)
            GraphElement(
              id: GraphIdentifier(member.resource.value),
              x: member.graph?.x ?? 0,
              y: member.graph?.y ?? index * 2,
              width: member.graph?.width ?? 4,
              height: member.graph?.height ?? 1,
              builder: (context) {
                final presentation = _resourceItem(context, member, view);
                final child = cardPadding == null
                    ? presentation
                    : Padding(padding: cardPadding, child: presentation);
                return _wrapResourceItem(context, view, member, child);
              },
            ),
        ],
        edges: [
          for (final edge in projection.edges)
            GraphEdge(
              id: edge.id,
              source: GraphIdentifier(edge.source.value),
              target: GraphIdentifier(edge.target.value),
              color: edgeColor,
              sourceSide: sides.$1,
              targetSide: sides.$2,
            ),
        ],
      ),
      onElementsMoved: childScope.enabled && !childScope.readOnly
          ? (changes) {
              _reportResourcesWrite(
                childScope,
                host.moveGraphNodes([
                  for (final change in changes)
                    PortableGraphPositionChange(
                      skir.ResourceId(value: change.id.id),
                      change.x,
                      change.y,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
      onElementsResized: childScope.enabled && !childScope.readOnly
          ? (changes) {
              _reportResourcesWrite(
                childScope,
                host.resizeGraphNodes([
                  for (final change in changes)
                    PortableGraphSizeChange(
                      skir.ResourceId(value: change.id.id),
                      change.width,
                      change.height,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
    );
  }

  Widget _renderResourceTimeline(
    BuildContext context,
    skir.TimelineResourcesLayout layout,
    PortableResourcesProjection projection,
    PortableResourcesView view,
    PortableResourcesHost host,
  ) {
    final childScope = view.scope;
    final tracks = <TimelineTrack>[];
    for (final member in view.members) {
      final cues = <TimelineElement>[];
      for (final cue in projection.timeline[member.resource] ?? const []) {
        final rendered = _timelineElement(context, cue, childScope, null);
        if (rendered != null) cues.add(rendered);
      }
      tracks.add(
        TimelineTrack(
          id: TimelineIdentifier(member.resource.value),
          header: (context) =>
              _resourceTimelineHeader(context, member, view, host),
          elements: cues,
        ),
      );
    }
    return Timeline(
      data: TimelineData(tracks: tracks),
      style: layout.appearance == null
          ? null
          : _resourceTimelineStyle(context, childScope, layout.appearance!),
      onElementsCommited: childScope.enabled && !childScope.readOnly
          ? (changes) async {
              _reportResourcesWrite(
                childScope,
                host.moveTimelineElements([
                  for (final change in changes)
                    PortableTimelineChange(
                      skir.ResourceId(value: change.id.id),
                      change.startFrame,
                      change.endFrame,
                    ),
                ], context: childScope.invocation),
              );
            }
          : null,
    );
  }

  /// A track header: the member through its item presentation and the
  /// application's member interaction, like every other layout, beside the
  /// track's membership menu.
  Widget _resourceTimelineHeader(
    BuildContext context,
    PortableResourceMember member,
    PortableResourcesView view,
    PortableResourcesHost host,
  ) {
    final childScope = view.scope;
    final editable = childScope.enabled && !childScope.readOnly;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            // Track headers can be narrower than an item row; the item keeps
            // a usable width and is clipped instead of overflowing.
            child: ConstraintsTransformBox(
              alignment: AlignmentDirectional.centerStart,
              clipBehavior: Clip.hardEdge,
              constraintsTransform: (constraints) => constraints.copyWith(
                minWidth: 0,
                maxWidth: max(constraints.maxWidth, _minimumTrackItemWidth),
              ),
              child: KeyedSubtree(
                key: ValueKey(member.resource),
                child: _wrapResourceItem(
                  context,
                  view,
                  member,
                  _resourceItem(context, member, view),
                ),
              ),
            ),
          ),
          PopupMenuButton<_ResourceMemberAction>(
            enabled: editable,
            onSelected: (action) => _reportResourcesWrite(
              childScope,
              host.removeMember(
                member,
                delete: action == _ResourceMemberAction.delete,
                context: childScope.invocation,
              ),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ResourceMemberAction.disconnect,
                child: Text("Disconnect"),
              ),
              PopupMenuItem(
                value: _ResourceMemberAction.delete,
                child: Text("Delete resource"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderResourceGrid(
    skir.GridResourcesLayout layout,
    PortableResourcesView view,
  ) {
    final scope = view.scope;
    final extent = _number(scope, layout.itemExtent);
    final ratio = _number(scope, layout.aspectRatio);
    final spacing = _number(scope, layout.spacing);
    if (extent == null || !extent.isFinite || extent <= 0) {
      return _diagnostic("Grid item extents must be finite and positive");
    }
    if (ratio == null || !ratio.isFinite || ratio <= 0) {
      return _diagnostic("Grid aspect ratios must be finite and positive");
    }
    if (spacing == null || !spacing.isFinite || spacing < 0) {
      return _diagnostic("Grid spacing must be finite and nonnegative");
    }
    if (view.members.isEmpty) return const _EmptyResources();
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return GridView.builder(
          shrinkWrap: !bounded,
          physics: bounded ? null : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: extent,
            childAspectRatio: ratio,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemCount: view.members.length,
          itemBuilder: (context, index) {
            final member = view.members[index];
            return KeyedSubtree(
              key: ValueKey(member.resource),
              child: _wrapResourceItem(
                context,
                view,
                member,
                _resourceItem(context, member, view),
              ),
            );
          },
        );
      },
    );
  }
}

/// Renders [member] through its item presentation, or the host chrome for its
/// layout when its type declares none.
Widget _resourceItem(
  BuildContext context,
  PortableResourceMember member,
  PortableResourcesView view,
) {
  final parent = view.scope;
  final projected = member.resourceProjection;
  final selected = parent.catalog?.selectPresentation(
    projected.configuration,
    skir.PresentationRole.item,
  );
  final content = switch (selected) {
    SelectedEditorPresentation() => PortablePresentationNodeRenderer(
      node: selected.material.layout,
      scope: parent.forResourcePresentation(projected, selected),
      fillAvailableSpace:
          view.layout == PortableResourcesLayoutKind.graph ||
          view.layout == PortableResourcesLayoutKind.grid,
    ),
    ConflictingEditorPresentation(:final candidates) => _diagnostic(
      "The item has ${candidates.length} conflicting presentations",
    ),
    UnavailableEditorPresentation(:final presentation) => _diagnostic(
      "Presentation ${presentation.namespace}:${presentation.name} is unavailable",
    ),
    _ => ResourceItemChrome(
      appearance: member.appearance,
      density: switch (view.layout) {
        PortableResourcesLayoutKind.grid => ResourceItemDensity.card,
        PortableResourcesLayoutKind.graph => ResourceItemDensity.node,
        _ => ResourceItemDensity.row,
      },
    ),
  };
  return PortableDiagnosticSource(
    diagnostics: projected.diagnostics,
    diagnosticFallback: projected.diagnosticFallback,
    observations: [
      PortableDiagnosticObservation(
        target: PortableDiagnosticTarget.value(
          skir.ValueLocation(resource: member.resource, path: editorRootPath),
        ),
        value: projected.value,
      ),
    ],
    child: content,
  );
}

/// Adds the application's member interaction, or keyboard and pointer
/// activation through the open callback when none is installed.
Widget _wrapResourceItem(
  BuildContext context,
  PortableResourcesView view,
  PortableResourceMember member,
  Widget child,
) {
  final interactions = PortableResourcesInteractionScope.maybeOf(context);
  if (interactions != null) {
    return interactions.itemBuilder(context, view, member, child);
  }
  return _DefaultResourceItem(view: view, member: member, child: child);
}

/// Focusable member that opens on tap or activation and publishes its hover,
/// focus and routed state to the item presentation.
class _DefaultResourceItem extends HookWidget {
  const _DefaultResourceItem({
    required this.view,
    required this.member,
    required this.child,
  });

  final PortableResourcesView view;
  final PortableResourceMember member;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);
    final focused = useState(false);
    final open = view.scope.openResource;
    void activate() => open?.call(member.resource);
    return Semantics(
      button: open != null,
      label: member.appearance.label,
      child: FocusableActionDetector(
        enabled: open != null,
        mouseCursor: open == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onShowHoverHighlight: (value) => hovered.value = value,
        onShowFocusHighlight: (value) => focused.value = value,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open == null ? null : activate,
          child: PresentationInteractionScope(
            value: PresentationInteraction(
              hovered: hovered.value,
              focused: focused.value,
              routed: member.resource == view.scope.routedResource,
              disabled: !view.scope.enabled,
              readOnly: view.scope.readOnly,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmptyResources extends StatelessWidget {
  const _EmptyResources();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(context.spacing.space3),
    child: Text(
      "Nothing here yet",
      style: context.theme.textTheme.bodySmall?.copyWith(
        color: context.colors.contentDisabled,
      ),
    ),
  );
}

/// Members as rows in link or order key order.
class _ResourceList extends StatelessWidget {
  const _ResourceList({required this.view});

  final PortableResourcesView view;

  @override
  Widget build(BuildContext context) {
    if (view.members.isEmpty) return const _EmptyResources();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final member in view.members)
          KeyedSubtree(
            key: ValueKey(member.resource),
            child: _wrapResourceItem(
              context,
              view,
              member,
              _resourceItem(context, member, view),
            ),
          ),
      ],
    );
  }
}

/// One group of a tree layout: members whose hierarchy path equals [path]
/// directly, and nested groups below it.
final class _ResourceTreeGroup {
  _ResourceTreeGroup(this.path, this.name);

  final String path;
  final String name;
  final children = <String, _ResourceTreeGroup>{};
  final members = <PortableResourceMember>[];

  /// Members of this group and every nested group.
  Iterable<PortableResourceMember> get allMembers sync* {
    yield* members;
    for (final child in children.values) {
      yield* child.allMembers;
    }
  }
}

/// Members grouped by a hierarchy path field. Each group header renders the
/// declared group node with the group bound as a hierarchy group value.
/// Expansion belongs to this widget and survives document updates.
class _ResourceTree extends HookWidget {
  const _ResourceTree({required this.layout, required this.view});

  final skir.TreeResourcesLayout layout;
  final PortableResourcesView view;

  @override
  Widget build(BuildContext context) {
    final toggled = useState(<String>{});
    final root = _ResourceTreeGroup("", "");
    for (final member in view.members) {
      final path =
          member.resourceProjection.value
              .editorValueAt(layout.path)
              ?.authoredPayload
              .authoredString ??
          "";
      var group = root;
      final segments = path.split(".").where((part) => part.isNotEmpty);
      var prefix = "";
      for (final segment in segments) {
        prefix = prefix.isEmpty ? segment : "$prefix.$segment";
        group = group.children.putIfAbsent(
          segment,
          () => _ResourceTreeGroup(prefix, segment),
        );
      }
      group.members.add(member);
    }
    bool expanded(String path) =>
        layout.initiallyExpanded != toggled.value.contains(path);
    void toggle(String path) {
      final next = {...toggled.value};
      if (!next.remove(path)) next.add(path);
      toggled.value = next;
    }

    final rows = <Widget>[];
    void addGroup(_ResourceTreeGroup group, int depth) {
      final children = group.children.values.toList()
        ..sort((left, right) => left.name.compareTo(right.name));
      for (final child in children) {
        final open = expanded(child.path);
        rows.add(
          KeyedSubtree(
            key: ValueKey("group:${child.path}"),
            child: _ResourceTreeGroupHeader(
              layout: layout,
              view: view,
              group: child,
              depth: depth,
              expanded: open,
              onToggle: () => toggle(child.path),
            ),
          ),
        );
        if (open) addGroup(child, depth + 1);
      }
      for (final member in group.members) {
        rows.add(
          KeyedSubtree(
            key: ValueKey(member.resource),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: depth * _treeIndent + _treeIndent,
              ),
              child: _wrapResourceItem(
                context,
                view,
                member,
                _resourceItem(context, member, view),
              ),
            ),
          ),
        );
      }
    }

    addGroup(root, 0);
    if (rows.isEmpty) return const _EmptyResources();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

const _treeIndent = 16.0;

class _ResourceTreeGroupHeader extends StatelessWidget {
  const _ResourceTreeGroupHeader({
    required this.layout,
    required this.view,
    required this.group,
    required this.depth,
    required this.expanded,
    required this.onToggle,
  });

  final skir.TreeResourcesLayout layout;
  final PortableResourcesView view;
  final _ResourceTreeGroup group;
  final int depth;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scope = view.scope;
    final node = layout.group;
    final header = node == null
        ? Text(group.name, overflow: TextOverflow.ellipsis)
        : PortablePresentationNodeRenderer(
            node: node,
            scope: scope.copyWith(
              bindings: {
                ...scope.bindings,
                layout.groupBindingId: PortableExpressionBinding(
                  value: _hierarchyGroupValue(scope.catalog, group),
                  schema: CompletePortablePresentationBinding(
                    skir.TypeUse.wrapNamed(hierarchyGroupUse),
                  ),
                ),
              },
            ),
          );
    final row = Padding(
      padding: EdgeInsetsDirectional.only(start: depth * _treeIndent),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: expanded
                ? "Collapse ${group.name}"
                : "Expand ${group.name}",
            icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right),
            onPressed: onToggle,
          ),
          Expanded(child: header),
        ],
      ),
    );
    return PortableResourcesInteractionScope.maybeOf(context)?.groupBuilder
            ?.call(
              context,
              view,
              PortableResourcesGroup(
                field: layout.path,
                path: group.path,
                name: group.name,
                members: group.allMembers.toList(growable: false),
              ),
              row,
            ) ??
        row;
  }
}

/// The hierarchy group value a tree group header binds, typed by the catalog's
/// published hierarchy group fields.
skir.DataValue _hierarchyGroupValue(
  CheckedEditorCatalog? catalog,
  _ResourceTreeGroup group,
) {
  final types = {
    for (final field
        in catalog?.fields(
              skir.TypeSelection.wrapComplete(hierarchyGroupUse),
            ) ??
            const <AppliedEditorField>[])
      field.template.key: field.type,
  };
  skir.DataValue typed(String field, skir.DataValue payload) =>
      switch (types[field]) {
        skir.TypeUse_namedWrapper(:final value) => skir.DataValue.createNamed(
          actualType: value,
          payload: payload,
        ),
        _ => payload,
      };
  return skir.DataValue.createNamed(
    actualType: hierarchyGroupUse,
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "path",
          value: typed("path", skir.DataValue.wrapStringValue(group.path)),
        ),
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue(group.name),
        ),
        skir.FieldValue(
          name: "members",
          value: typed(
            "members",
            skir.DataValue.createListValue(
              items: [
                for (final member in group.members)
                  skir.ListItem(
                    id: skir.ItemId(value: member.resource.value),
                    value: member.resource.toExpressionValue(),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Orders evaluated keys: missing keys last, then text, numbers and booleans
/// by their natural order, and anything else by canonical text.
int _compareOrderKeys(skir.DataValue? left, skir.DataValue? right) {
  if (left == null || right == null) {
    return left == null ? (right == null ? 0 : 1) : -1;
  }
  final a = left.authoredPayload;
  final b = right.authoredPayload;
  double? number(skir.DataValue value) => switch (value) {
    skir.DataValue_integerWrapper(:final value) => double.tryParse(value),
    skir.DataValue_floatWrapper(:final value) => value,
    skir.DataValue_decimalWrapper(:final value) => double.tryParse(value),
    _ => null,
  };
  if ((number(a), number(b)) case (final x?, final y?)) return x.compareTo(y);
  if ((a.authoredString, b.authoredString) case (final x?, final y?)) {
    return x.toLowerCase().compareTo(y.toLowerCase());
  }
  if ((a, b) case (
    skir.DataValue_booleanWrapper(value: final x),
    skir.DataValue_booleanWrapper(value: final y),
  )) {
    return x == y ? 0 : (x ? 1 : -1);
  }
  return canonicalAuthoredValue(a).compareTo(canonicalAuthoredValue(b));
}

enum _ResourceMemberAction { disconnect, delete }

/// The narrowest width a timeline track header lays its member out at.
const _minimumTrackItemWidth = 72.0;

void _reportResourcesWrite(
  PortablePresentationScope scope,
  PortablePresentationWriteResult result,
) {
  unawaited(
    scope.operations.run(
      key: const PortableOperationKey.status(),
      operation: () => result,
    ),
  );
}

TimelineElement? _timelineElement(
  BuildContext context,
  PortableTimelineCueProjection cue,
  PortablePresentationScope scope,
  TimelineIdentifier? parent,
) {
  final id = TimelineIdentifier(cue.resource.value);
  final color = Theme.of(context).colorScheme.primary;
  return switch (cue.placement) {
    PortableTimelineKeyframe(:final frame) => TimelineKeyframe(
      id: id,
      frame: frame,
      parentId: parent,
      color: color,
      builder: (_, _) => GestureDetector(
        onTap: scope.openResource == null
            ? null
            : () => scope.openResource!(cue.resource),
        child: Semantics(label: cue.label, child: const Icon(Icons.circle)),
      ),
    ),
    PortableTimelineSegment(:final startFrame, :final endFrame) =>
      TimelineSegment(
        id: id,
        startFrame: startFrame,
        endFrame: endFrame,
        parentId: parent,
        color: color,
        children: [
          for (final child in cue.children)
            if (_timelineElement(context, child, scope, id) case final value?
                when value.endFrame <= endFrame - startFrame)
              value,
        ],
        builder: (_, _) => GestureDetector(
          onTap: scope.openResource == null
              ? null
              : () => scope.openResource!(cue.resource),
          child: Text(cue.label, overflow: TextOverflow.ellipsis),
        ),
      ),
  };
}

TimelineStyle _resourceTimelineStyle(
  BuildContext context,
  PortablePresentationScope scope,
  skir.ResourceTimelineAppearance appearance,
) {
  final base = TimelineStyle.fallback(Theme.of(context));
  double dimension(double? value, double fallback, {bool positive = false}) {
    if (value == null) return fallback;
    if (!value.isFinite || (positive ? value <= 0 : value < 0)) {
      throw const PresentationValueFailure(
        "Timeline dimensions must be finite and within their allowed range",
      );
    }
    return value;
  }

  Color color(skir.PresentationColor? value, Color fallback) =>
      _color(context, scope, value) ?? fallback;
  final palette = base.palette;
  return TimelineStyle(
    rulerHeight: dimension(
      appearance.rulerHeight,
      base.rulerHeight,
      positive: true,
    ),
    trackPadding: dimension(appearance.trackPadding, base.trackPadding),
    laneHeight: dimension(
      appearance.laneHeight,
      base.laneHeight,
      positive: true,
    ),
    laneGap: dimension(appearance.laneGap, base.laneGap),
    headerPadding: dimension(appearance.headerPadding, base.headerPadding),
    minHeaderWidth: base.minHeaderWidth,
    maxHeaderWidth: base.maxHeaderWidth,
    minPixelsPerFrame: base.minPixelsPerFrame,
    maxPixelsPerFrame: base.maxPixelsPerFrame,
    gridMinorMinSpacing: base.gridMinorMinSpacing,
    gridMajorMinSpacing: base.gridMajorMinSpacing,
    gridTickSteps: base.gridTickSteps,
    trailingFrames: base.trailingFrames,
    minSegmentWidth: base.minSegmentWidth,
    keyframeWidth: base.keyframeWidth,
    keyframeSize: base.keyframeSize,
    edgeHandleWidth: base.edgeHandleWidth,
    palette: TimelinePalette(
      headerBackground: color(appearance.headerColor, palette.headerBackground),
      rulerBackground: color(appearance.rulerColor, palette.rulerBackground),
      trackBackground: color(appearance.trackColor, palette.trackBackground),
      trackAltBackground: color(
        appearance.alternateTrackColor,
        palette.trackAltBackground,
      ),
      gridMinor: color(appearance.gridMinorColor, palette.gridMinor),
      gridMajor: color(appearance.gridMajorColor, palette.gridMajor),
      headerDivider: palette.headerDivider,
      textMuted: color(appearance.textMutedColor, palette.textMuted),
    ),
  );
}
