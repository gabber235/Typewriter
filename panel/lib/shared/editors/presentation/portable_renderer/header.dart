part of "../portable_presentation_renderer.dart";

/// Keeps authored actions in their lexical scope while merging only proven
/// collection command equivalents. Disclosure retains the body and excludes
/// collapsed focus. In a collection row, the disclosure and the first pinned
/// action are its RowLanding, where focus lands after a removal.
final class _AuthoredPresentationHeader extends HookWidget {
  const _AuthoredPresentationHeader({
    required this.header,
    required this.body,
    required this.scope,
    this.contained = false,
    this.collectionControls = const [],
  });
  final skir.PresentationHeader header;
  final Widget body;
  final PortablePresentationScope scope;
  final bool contained;
  final List<_SuppliedHeaderControl> collectionControls;

  @override
  Widget build(BuildContext context) {
    final controller = useExpansibleController();
    useListenable(controller);
    useEffect(() {
      if (header.initiallyExpanded ?? true) {
        controller.expand();
      } else {
        controller.collapse();
      }
      return null;
    }, [header.initiallyExpanded]);
    final expanded = controller.isExpanded;
    void toggleExpanded() => controller.toggle();

    return PortableDiagnosticAnchor(
      node: PortableDiagnosticNode(
        kind: PortableDiagnosticNodeKind.header,
        observations: header.binding == null
            ? const []
            : [
                PortableDiagnosticObservation(
                  target: scope.diagnosticTarget(header.binding!),
                  value: scope.read(header.binding!),
                ),
              ],
      ),
      builder: (context, summary, owner) {
        final raw = [
          for (final item in header.items)
            _ScopedHeaderDeclaration(item: item, scope: scope),
        ];
        final supplied = _remainingCollectionControls(raw, collectionControls);
        final items = _items(context);
        final before = items
            .where(
              (item) =>
                  item.placement.kind ==
                  skir.HeaderActionPlacement_kind.beforeTitleConst,
            )
            .toList();
        final after = items
            .where(
              (item) =>
                  item.placement.kind ==
                  skir.HeaderActionPlacement_kind.afterTitleConst,
            )
            .toList();
        final end = items
            .where(
              (item) =>
                  item.placement.kind ==
                      skir.HeaderActionPlacement_kind.endConst ||
                  item.placement.kind ==
                      skir.HeaderActionPlacement_kind.unknown,
            )
            .toList();
        final title = _title(context);
        final description = header.description == null
            ? null
            : _string(scope, header.description!);
        final collapsible = header.initiallyExpanded != null;
        final contentPadding = header.contentPadding == null
            ? EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space1,
              )
            : _presentationInsets(header.contentPadding);
        // Colour and shape changes fade with ink.
        final ink = motionTimeline(context, MotionToken.ink);
        final headerWidget = Material(
          animationDuration: ink.duration,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: context.shapes.mediumRadius,
              bottom: expanded ? Radius.zero : context.shapes.mediumRadius,
            ),
          ),
          color: context.colors.surface.withValues(alpha: 0),
          child: Button(
            face: ButtonFace.bare,
            label: "",
            onPressed: collapsible && scope.enabled ? toggleExpanded : null,
            child: Padding(
              padding: header.headerPadding == null
                  ? EdgeInsets.symmetric(
                      horizontal: context.spacing.space2,
                      vertical: context.spacing.space1,
                    )
                  : _presentationInsets(header.headerPadding),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PortableHeaderRow(
                      before: [
                        if (collapsible)
                          _expandButton(expanded, toggleExpanded),
                        // The marker pops in itself; the row only makes room.
                        MotionSize(
                          grow: MotionToken.loadIn,
                          shrink: MotionToken.listOut,
                          clipBehavior: Clip.none,
                          child: summary.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: EdgeInsets.only(
                                    right: context.spacing.space3,
                                  ),
                                  child: PortableDiagnosticHeaderMarker(
                                    summary: summary,
                                  ),
                                ),
                        ),
                        for (final item in before) item.widget,
                        for (final item in supplied)
                          if (item.command is _ReorderCommand)
                            item.build(context),
                      ],
                      title: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: title,
                      ),
                      after: [
                        for (final item in after) item.widget,
                        for (final item in supplied)
                          if (item.command is! _ReorderCommand)
                            item.build(context),
                      ],
                      end: [for (final item in end) item.widget],
                    ),
                    if (description != null)
                      Padding(
                        padding: EdgeInsets.only(top: context.spacing.space1),
                        child: switch (description) {
                          _ResolvedValue(:final value) when value.isNotEmpty =>
                            Text(
                              value,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          _ResolvedFailure(:final message) => _diagnostic(
                            message,
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        final plainTitle = _plainTitle();
        final bodyWidget = Padding(
          padding: contentPadding,
          child: plainTitle == null
              ? body
              : _PortableHeaderTitle(title: plainTitle, child: body),
        );
        final severity = summary.highestSeverity;
        final color = severity?.color(context);
        final fill = severity == skir.DiagnosticSeverity.error
            ? context.theme.colorScheme.errorContainer
            : color;
        final headerContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerWidget,
            PortableDiagnosticMessages(
              diagnostics: summary.direct,
              fixed: summary.fixed,
            ),
          ],
        );
        final content = AnimatedContainer(
          duration: ink.duration,
          curve: ink.curve,
          decoration: BoxDecoration(
            color:
                fill?.withValues(alpha: 0.18) ??
                context.colors.surface.withValues(alpha: 0),
            borderRadius: context.shapes.mediumBorderRadius,
            border: color != null && !expanded
                ? Border.all(color: color.withValues(alpha: 0.8))
                : null,
          ),
          padding: EdgeInsets.only(
            bottom: severity != null && expanded ? context.spacing.space1 : 0,
          ),
          child: collapsible
              ? GrowingCard(
                  controller: controller,
                  maintainState: true,
                  header: (context, _) => headerContent,
                  body: (context) => bodyWidget,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [headerContent, bodyWidget],
                ),
        );
        return contained
            ? content
            : DepthBox(enabled: collapsible, child: content);
      },
    );
  }

  Widget _expandButton(bool expanded, VoidCallback toggleExpanded) {
    return RowLanding(
      child: Button(
        face: ButtonFace.icon,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
        label: expanded ? "Collapse" : "Expand",
        tooltip: expanded ? "Collapse" : "Expand",
        onPressed: scope.enabled ? toggleExpanded : null,
      ),
    );
  }

  Widget _title(BuildContext context) => switch (header.title) {
    skir.PresentationHeaderTitle_textWrapper(:final value) => switch (_string(
      scope,
      value,
    )) {
      _ResolvedValue(:final value) => SectionTitle(title: value),
      _ResolvedFailure(:final message) => _diagnostic(message),
    },
    skir.PresentationHeaderTitle_presentationWrapper(:final value) =>
      PortablePresentationNodeRenderer(node: value, scope: scope),
    _ => _diagnostic("The presentation header title is unavailable"),
  };

  String? _plainTitle() => switch (header.title) {
    skir.PresentationHeaderTitle_textWrapper(:final value) => switch (_string(
      scope,
      value,
    )) {
      _ResolvedValue(:final value) => value,
      _ => null,
    },
    _ => null,
  };

  List<_AuthoredHeaderItem> _items(BuildContext context) {
    final resolved = <_AuthoredHeaderItem>[];
    var order = 0;
    var landingPlaced = false;
    final contributed = collectionControls
        .map((item) => item.command)
        .nonNulls
        .toSet();
    for (final item in header.items) {
      final command = _ScopedHeaderDeclaration(
        item: item,
        scope: scope,
      ).command;
      final pinned = command != null && contributed.contains(command);
      final currentOrder = order++;
      switch (item) {
        case skir.HeaderItem_buttonWrapper(:final value):
          final placement = pinned
              ? skir.HeaderActionPlacement.afterTitle
              : value.placement;
          final visible = _boolean(scope, value.visibleIf, fallback: true);
          if (visible case _ResolvedValue(value: false)) continue;
          if (visible case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, placement, currentOrder),
            );
            continue;
          }
          final labelResult = _string(scope, value.label);
          if (labelResult case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, placement, currentOrder),
            );
            continue;
          }
          final label = (labelResult as _ResolvedValue<String>).value;
          final iconName = _resolvedString(value.icon);
          final tooltipResult = value.tooltip == null
              ? _ResolvedValue(label)
              : _string(scope, value.tooltip!);
          final enabledResult = _boolean(
            scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              scope.canExecuteActionFor(value.action) &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final tooltip = switch (enabledResult) {
            _ResolvedFailure(:final message) => message,
            _ => switch (tooltipResult) {
              _ResolvedValue(:final value) => value,
              _ResolvedFailure(:final message) => message,
            },
          };
          final destructive =
              value.tone.kind == skir.HeaderActionTone_kind.destructiveConst;
          final landing =
              pinned &&
              !landingPlaced &&
              header.initiallyExpanded == null &&
              enabled;
          landingPlaced = landingPlaced || landing;
          final button = Builder(
            builder: (buttonContext) {
              void activate() =>
                  _invokeAction(context, buttonContext, value.action);
              final icon = iconName == null
                  ? const Icon(Icons.more_horiz, size: 18)
                  : Icones(iconName, size: 18);
              if (pinned) {
                final pinnedButton = Button(
                  face: ButtonFace.icon,
                  tooltip: tooltip,
                  onPressed: enabled ? activate : null,
                  color: destructive ? context.colors.dangerText : null,
                  icon: icon,
                  label: label,
                );
                return landing ? RowLanding(child: pinnedButton) : pinnedButton;
              }
              return Button(
                onPressed: enabled ? activate : null,
                color: destructive ? context.colors.dangerText : null,
                tooltip: tooltip,
                icon: icon,
                label: label,
              );
            },
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: button,
              placement: placement,
              priority: _priority(value.priority),
              order: currentOrder,
            ),
          );
        case skir.HeaderItem_booleanToggleWrapper(:final value):
          final visible = _boolean(scope, value.visibleIf, fallback: true);
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(scope, value.label);
          final checked = _boolean(scope, value.checked);
          final failure = switch ((visible, label, checked)) {
            (_ResolvedFailure(:final message), _, _) => message,
            (_, _ResolvedFailure(:final message), _) => message,
            (_, _, _ResolvedFailure(:final message)) => message,
            _ => null,
          };
          if (failure != null) {
            resolved.add(
              _failureItem(context, failure, value.placement, currentOrder),
            );
            continue;
          }
          final labelValue = (label as _ResolvedValue<String>).value;
          final checkedValue = (checked as _ResolvedValue<bool>).value;
          final enabledResult = _boolean(
            scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              scope.canExecuteActionFor(value.action) &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final checkbox = Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            },
            child: Builder(
              builder: (checkboxContext) => Checkbox(
                value: checkedValue,
                semanticLabel: labelValue,
                visualDensity: VisualDensity.compact,
                onChanged: enabled
                    ? (_) =>
                          _invokeAction(context, checkboxContext, value.action)
                    : null,
              ),
            ),
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: value.tooltip == null
                  ? enabledResult is _ResolvedFailure<bool>
                        ? PanelTooltip(
                            message: enabledResult.message,
                            child: checkbox,
                          )
                        : checkbox
                  : PanelTooltip(
                      message: switch (_string(scope, value.tooltip!)) {
                        _ResolvedValue(:final value) => value,
                        _ResolvedFailure(:final message) => message,
                      },
                      child: checkbox,
                    ),
              placement: value.placement,
              priority: _priority(value.priority),
              order: currentOrder,
            ),
          );
        case skir.HeaderItem_reorderHandleWrapper(:final value):
          final visible = _boolean(scope, value.visibleIf, fallback: true);
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(scope, value.label);
          final target = _reorderTarget(value.source);
          final failure = switch ((visible, label, target)) {
            (_ResolvedFailure(:final message), _, _) => message,
            (_, _ResolvedFailure(:final message), _) => message,
            (_, _, null) =>
              "The reorder source is not a current collection item",
            _ => null,
          };
          if (failure != null) {
            resolved.add(
              _failureItem(
                context,
                failure,
                skir.HeaderActionPlacement.beforeTitle,
                currentOrder,
              ),
            );
            continue;
          }
          final actualTarget = target!;
          final labelValue = (label as _ResolvedValue<String>).value;
          final enabledResult = _boolean(
            scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final tooltip = switch (enabledResult) {
            _ResolvedFailure(:final message) => message,
            _ =>
              value.tooltip == null
                  ? labelValue
                  : switch (_string(scope, value.tooltip!)) {
                      _ResolvedValue(:final value) => value,
                      _ResolvedFailure(:final message) => message,
                    },
          };
          resolved.add(
            _AuthoredHeaderItem(
              widget: _AuthoredReorderHandle(
                index: actualTarget.index,
                label: tooltip,
                enabled: enabled,
                canMoveEarlier: actualTarget.index > 0,
                canMoveLater:
                    actualTarget.index < actualTarget.items.length - 1,
                onMoveEarlier: () => _moveReorderTarget(
                  context,
                  actualTarget,
                  after: actualTarget.index == 1
                      ? null
                      : actualTarget.items[actualTarget.index - 2].id,
                ),
                onMoveLater: () => _moveReorderTarget(
                  context,
                  actualTarget,
                  after: actualTarget.items[actualTarget.index + 1].id,
                ),
              ),
              placement: skir.HeaderActionPlacement.beforeTitle,
              priority: 0,
              order: currentOrder,
            ),
          );
        case skir.HeaderItem_unknown():
      }
    }
    resolved.sort((left, right) {
      final priority = right.priority.compareTo(left.priority);
      return priority == 0 ? left.order.compareTo(right.order) : priority;
    });
    return resolved;
  }

  _AuthoredHeaderItem _failureItem(
    BuildContext context,
    String message,
    skir.HeaderActionPlacement placement,
    int order,
  ) => _AuthoredHeaderItem(
    widget: PanelTooltip(
      message: message,
      child: Icon(
        Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
        semanticLabel: message,
      ),
    ),
    placement: placement,
    priority: 0,
    order: order,
  );

  _AuthoredReorderTarget? _reorderTarget(skir.BindingRef source) {
    final resolved = scope.sourceReference(source);
    if (resolved == null) return null;
    final segments = resolved.path.segments.toList(growable: false);
    final last = segments.lastOrNull;
    if (last is! skir.PathSegment_itemWrapper) return null;
    final item = last.value.id;
    final containing = skir.BindingRef(
      bindingId: resolved.bindingId,
      path: skir.ValuePath(segments: segments.take(segments.length - 1)),
    );
    final items = scope.read(containing)?.authoredItems?.toList();
    if (items == null) return null;
    final index = items.indexWhere((candidate) => candidate.id == item);
    if (index < 0) return null;
    return _AuthoredReorderTarget(
      containing: containing,
      item: item,
      items: items,
      index: index,
    );
  }

  void _moveReorderTarget(
    BuildContext context,
    _AuthoredReorderTarget target, {
    required skir.ItemId? after,
  }) {
    scope.moveListItem(target.containing, target.item, after);
  }

  int _priority(skir.ExpressionNode? value) {
    if (value == null) return 0;
    return switch (scope.evaluate(value)) {
      PortableExpressionAvailable(:final value) =>
        switch (value.authoredPayload) {
          skir.DataValue_integerWrapper(:final value) =>
            BigInt.tryParse(value)?.toInt() ?? 0,
          skir.DataValue_floatWrapper(:final value) => value.round(),
          _ => 0,
        },
      _ => 0,
    };
  }

  String? _resolvedString(skir.ExpressionNode value) =>
      switch (scope.evaluate(value)) {
        PortableExpressionAvailable(:final value) => value.authoredString,
        _ => null,
      };

  void _invokeAction(
    BuildContext declarationContext,
    BuildContext occurrenceContext,
    skir.EditorAction action,
  ) {
    final menu = _CollectionMenuInvocation.maybeOf(occurrenceContext);
    unawaited(_runAction(declarationContext, action, closeMenu: menu?.close));
  }

  Future<void> _runAction(
    BuildContext context,
    skir.EditorAction editorAction, {
    VoidCallback? closeMenu,
  }) async {
    closeMenu?.call();
    if (!context.mounted) return;
    // A removal moves focus when its row leaves (RowFocus), after the menu
    // handed focus back.
    await scope.executeAction(editorAction);
  }
}

final class _PortableHeaderTitle extends InheritedWidget {
  const _PortableHeaderTitle({required this.title, required super.child});

  final String title;

  static String? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PortableHeaderTitle>()?.title;

  @override
  bool updateShouldNotify(covariant _PortableHeaderTitle oldWidget) =>
      title != oldWidget.title;
}

final class _AuthoredHeaderItem {
  const _AuthoredHeaderItem({
    required this.widget,
    required this.placement,
    required this.priority,
    required this.order,
  });

  final Widget widget;
  final skir.HeaderActionPlacement placement;
  final int priority;
  final int order;
}
