part of "../portable_presentation_renderer.dart";

final class _AuthoredPresentationHeader extends StatefulWidget {
  const _AuthoredPresentationHeader({
    required this.header,
    required this.body,
    required this.scope,
  });

  final skir.PresentationHeader header;
  final Widget body;
  final PortablePresentationScope scope;

  @override
  State<_AuthoredPresentationHeader> createState() =>
      _AuthoredPresentationHeaderState();
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

final class _AuthoredPresentationHeaderState
    extends State<_AuthoredPresentationHeader> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.header.initiallyExpanded ?? true;
  }

  @override
  void didUpdateWidget(covariant _AuthoredPresentationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.header.initiallyExpanded != widget.header.initiallyExpanded) {
      _expanded = widget.header.initiallyExpanded ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              item.placement.kind == skir.HeaderActionPlacement_kind.endConst ||
              item.placement.kind == skir.HeaderActionPlacement_kind.unknown,
        )
        .toList();
    final title = _title();
    final description = widget.header.description == null
        ? null
        : _string(widget.scope, widget.header.description!);
    final collapsible = widget.header.initiallyExpanded != null;
    final contentPadding = widget.header.contentPadding == null
        ? EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: context.spacing.space1,
          )
        : _presentationInsets(widget.header.contentPadding);
    final header = Material(
      color: context.colors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: collapsible && widget.scope.enabled ? _toggleExpanded : null,
        child: Padding(
          padding: widget.header.headerPadding == null
              ? EdgeInsets.symmetric(
                  horizontal: context.spacing.space2,
                  vertical: context.spacing.space1,
                )
              : _presentationInsets(widget.header.headerPadding),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PortableHeaderRow(
                  before: [
                    if (collapsible) _expandButton(),
                    for (final item in before) item.widget,
                  ],
                  title: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: title,
                  ),
                  after: [for (final item in after) item.widget],
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
                      _ResolvedFailure(:final message) => _diagnostic(message),
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
    final body = Padding(
      padding: contentPadding,
      child: plainTitle == null
          ? widget.body
          : _PortableHeaderTitle(title: plainTitle, child: widget.body),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Visibility(
          visible: _expanded,
          maintainState: true,
          maintainAnimation: true,
          child: body,
        ),
      ],
    );
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  Widget _expandButton() => IconButton(
    tooltip: _expanded ? "Collapse" : "Expand",
    onPressed: widget.scope.enabled ? _toggleExpanded : null,
    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
  );

  Widget _title() => switch (widget.header.title) {
    skir.PresentationHeaderTitle_textWrapper(:final value) => switch (_string(
      widget.scope,
      value,
    )) {
      _ResolvedValue(:final value) => Text(
        value,
        style: context.theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      _ResolvedFailure(:final message) => _diagnostic(message),
    },
    skir.PresentationHeaderTitle_presentationWrapper(:final value) =>
      PortablePresentationNodeRenderer(node: value, scope: widget.scope),
    _ => _diagnostic("The presentation header title is unavailable"),
  };

  String? _plainTitle() => switch (widget.header.title) {
    skir.PresentationHeaderTitle_textWrapper(:final value) => switch (_string(
      widget.scope,
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
    for (final item in widget.header.items) {
      final currentOrder = order++;
      switch (item) {
        case skir.HeaderItem_buttonWrapper(:final value):
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          if (visible case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, value.placement, currentOrder),
            );
            continue;
          }
          final labelResult = _string(widget.scope, value.label);
          if (labelResult case _ResolvedFailure(:final message)) {
            resolved.add(
              _failureItem(context, message, value.placement, currentOrder),
            );
            continue;
          }
          final label = (labelResult as _ResolvedValue<String>).value;
          final iconName = _resolvedString(value.icon);
          final tooltipResult = value.tooltip == null
              ? _ResolvedValue(label)
              : _string(widget.scope, value.tooltip!);
          final enabledResult = _boolean(
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
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
          final button = TextButton.icon(
            onPressed: enabled
                ? () => _runAction(
                    context,
                    value.action,
                    value.confirmation,
                    destructive: destructive,
                  )
                : null,
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            icon: Icon(
              iconName == null ? Icons.more_horiz : _materialIcon(iconName),
              size: 18,
            ),
            label: Text(label),
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: Tooltip(message: tooltip, child: button),
              placement: value.placement,
              priority: _priority(value.priority),
              order: currentOrder,
            ),
          );
        case skir.HeaderItem_booleanToggleWrapper(:final value):
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(widget.scope, value.label);
          final checked = _boolean(widget.scope, value.checked);
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
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final checkbox = Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            },
            child: Checkbox(
              value: checkedValue,
              semanticLabel: labelValue,
              visualDensity: VisualDensity.compact,
              onChanged: enabled
                  ? (_) => _runAction(context, value.action, value.confirmation)
                  : null,
            ),
          );
          resolved.add(
            _AuthoredHeaderItem(
              widget: value.tooltip == null
                  ? enabledResult is _ResolvedFailure<bool>
                        ? Tooltip(
                            message: enabledResult.message,
                            child: checkbox,
                          )
                        : checkbox
                  : Tooltip(
                      message: switch (_string(widget.scope, value.tooltip!)) {
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
          final visible = _boolean(
            widget.scope,
            value.visibleIf,
            fallback: true,
          );
          if (visible case _ResolvedValue(value: false)) continue;
          final label = _string(widget.scope, value.label);
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
            widget.scope,
            value.enabledIf,
            fallback: true,
          );
          final enabled =
              widget.scope.canExecuteAction &&
              enabledResult is _ResolvedValue<bool> &&
              enabledResult.value;
          final tooltip = switch (enabledResult) {
            _ResolvedFailure(:final message) => message,
            _ =>
              value.tooltip == null
                  ? labelValue
                  : switch (_string(widget.scope, value.tooltip!)) {
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
                  actualTarget,
                  after: actualTarget.index == 1
                      ? null
                      : actualTarget.items[actualTarget.index - 2].id,
                ),
                onMoveLater: () => _moveReorderTarget(
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
    widget: Tooltip(
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
    final resolved = widget.scope.sourceReference(source);
    if (resolved == null) return null;
    final segments = resolved.path.segments.toList(growable: false);
    final last = segments.lastOrNull;
    if (last is! skir.PathSegment_itemWrapper) return null;
    final item = last.value.id;
    final containing = skir.BindingRef(
      bindingId: resolved.bindingId,
      path: skir.ValuePath(segments: segments.take(segments.length - 1)),
    );
    final items = widget.scope.read(containing)?.authoredItems?.toList();
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
    _AuthoredReorderTarget target, {
    required skir.ItemId? after,
  }) {
    widget.scope.moveListItem(target.containing, target.item, after);
  }

  int _priority(skir.ExpressionNode? value) {
    if (value == null) return 0;
    return switch (widget.scope.evaluate(value)) {
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
      switch (widget.scope.evaluate(value)) {
        PortableExpressionAvailable(:final value) => value.authoredString,
        _ => null,
      };

  Future<void> _runAction(
    BuildContext context,
    skir.EditorAction editorAction,
    skir.HeaderActionConfirmation? confirmation, {
    bool destructive = false,
  }) async {
    if (confirmation != null) {
      final title = _resolvedString(confirmation.title);
      final message = _resolvedString(confirmation.message);
      final label = _resolvedString(confirmation.confirmationLabel);
      if (title == null || message == null || label == null) {
        widget.scope.reportStatus?.call(
          "The action confirmation is unavailable",
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              child: Text(label),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await widget.scope.executeAction(editorAction);
  }
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
