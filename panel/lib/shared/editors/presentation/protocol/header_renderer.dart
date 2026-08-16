import "dart:math" as math;

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:iconify_flutter_plus/icons/ic.dart";
import "package:iconify_flutter_plus/icons/material_symbols.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "header_action_resolution.dart";
part "header_renderer.freezed.dart";

class PresentationHeaderChrome extends StatefulWidget {
  const PresentationHeaderChrome({
    required this.nodeId,
    required this.expansionKey,
    required this.header,
    required this.scope,
    required this.child,
    this.contained = false,
    super.key,
  });

  final String nodeId;
  final HeaderExpansionKey expansionKey;
  final PresentationHeader header;
  final PresentationRenderScope scope;
  final Widget child;
  final bool contained;

  @override
  State<PresentationHeaderChrome> createState() =>
      _PresentationHeaderChromeState();
}

class _PresentationHeaderChromeState extends State<PresentationHeaderChrome> {
  late ExpansibleController _expansibleController;
  late final FocusNode _headerFocusNode;

  @override
  void initState() {
    super.initState();
    _expansibleController = _createExpansibleController();
    _headerFocusNode = FocusNode(debugLabel: "Presentation header");
  }

  @override
  void didUpdateWidget(PresentationHeaderChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final movedWithSameExpansionKey =
        oldWidget.expansionKey == widget.expansionKey &&
        oldWidget.nodeId != widget.nodeId;
    if (oldWidget.expansionKey != widget.expansionKey ||
        oldWidget.header.initiallyExpanded != widget.header.initiallyExpanded) {
      _expansibleController.dispose();
      _expansibleController = _createExpansibleController();
    }
    if (movedWithSameExpansionKey) _ensureFocusedHeaderVisible();
  }

  void _ensureFocusedHeaderVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_headerFocusNode.hasPrimaryFocus) return;
      final headerContext = _headerFocusNode.context;
      if (headerContext == null) return;
      Scrollable.ensureVisible(headerContext, alignment: 0.5);
    });
  }

  @override
  void dispose() {
    _expansibleController.dispose();
    _headerFocusNode.dispose();
    super.dispose();
  }

  bool _storedExpansion() => widget.scope.expansionStore.value(
    key: widget.expansionKey,
    initial: widget.header.initiallyExpanded ?? true,
  );

  ExpansibleController _createExpansibleController() {
    final controller = ExpansibleController();
    if (_storedExpansion()) controller.expand();
    return controller;
  }

  void _toggle() {
    if (widget.header.initiallyExpanded == null) return;
    _expansibleController.toggle();
    widget.scope.expansionStore.set(
      key: widget.expansionKey,
      expanded: _expansibleController.isExpanded,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.header.resolve(widget.scope);
    final items = resolved.items.where((item) => item.visible).toList();
    final shortcuts = [
      for (final item in items) ...item.shortcuts(context, widget.scope),
    ];
    final headerRow = _HeaderRow(
      title: resolved.title,
      items: items,
      scope: widget.scope,
      collapsible: widget.header.initiallyExpanded != null,
      expanded: _expansibleController.isExpanded,
    );
    final collapsible = widget.header.initiallyExpanded != null;
    final headerContent = ManagedActionSet(
      shortcuts: shortcuts,
      child: Material(
        color: Colors.transparent,
        borderRadius: context.shapes.smallBorderRadius,
        child: InkWell(
          focusNode: _headerFocusNode,
          onTap: collapsible ? _toggle : null,
          borderRadius: context.shapes.smallBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: collapsible ? context.spacing.space1 : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.spacing.space1,
              children: [
                headerRow,
                if (resolved.description.isNotEmpty) ...[
                  SizedBox(
                    key: ValueKey((
                      "presentationHeaderDescription",
                      widget.nodeId,
                    )),
                    width: double.infinity,
                    child: Text(
                      resolved.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.contentSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final content = collapsible
        ? Expansible(
            controller: _expansibleController,
            animationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 240),
              curve: Curves.easeOut,
            ),
            maintainState: true,
            headerBuilder: (context, animation) => headerContent,
            bodyBuilder: (context, animation) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space2,
                vertical: context.spacing.space1,
              ),
              child: widget.child,
            ),
            expansibleBuilder: (context, header, body, animation) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, body],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [headerContent, widget.child],
          );
    return widget.contained
        ? content
        : DepthBox(enabled: collapsible, child: content);
  }
}

class _HeaderRow extends StatefulWidget {
  const _HeaderRow({
    required this.title,
    required this.items,
    required this.scope,
    required this.collapsible,
    required this.expanded,
  });

  final PresentationHeaderTitle? title;
  final List<_ResolvedHeaderItem> items;
  final PresentationRenderScope scope;
  final bool collapsible;
  final bool expanded;

  @override
  State<_HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<_HeaderRow> {
  var _visibleEndCount = 0;

  @override
  Widget build(BuildContext context) {
    final reorderHandles = widget.items
        .whereType<_ResolvedHeaderReorderHandleItem>()
        .toList();
    final beforeTitle = widget.items.at(HeaderActionPlacement.beforeTitle);
    final afterTitle = widget.items.at(HeaderActionPlacement.afterTitle);
    final end = widget.items.at(HeaderActionPlacement.end);
    final beforeTitleWidgets = <Widget>[
      if (widget.collapsible) _collapseAffordance(widget.expanded),
      for (final item in reorderHandles)
        item.inlineWidget(context, widget.scope),
      for (final item in beforeTitle) item.inlineWidget(context, widget.scope),
    ];
    final overflow = end.skip(_visibleEndCount.clamp(0, end.length)).toList();
    return _HeaderLayout(
      beforeTitleCount: beforeTitleWidgets.length,
      afterTitleCount: afterTitle.length,
      endCount: end.length,
      textDirection: Directionality.of(context),
      onVisibleEndCountChanged: _handleVisibleEndCountChanged,
      children: [
        ...beforeTitleWidgets,
        switch (widget.title) {
          PresentationHeaderTextTitle(:final value) => SectionTitle(
            title: widget.scope.expressionText(value),
          ),
          PresentationHeaderNodeTitle(:final node) => PresentationNodeRenderer(
            node: node,
            scope: widget.scope,
          ),
          null => const SizedBox.shrink(),
        },
        for (final item in afterTitle) item.inlineWidget(context, widget.scope),
        for (final item in end) item.inlineWidget(context, widget.scope),
        if (end.isNotEmpty)
          _OverflowItems(
            items: overflow.isEmpty ? end : overflow,
            scope: widget.scope,
          ),
      ],
    );
  }

  Widget _collapseAffordance(bool expanded) => SizedBox.square(
    dimension: 40,
    child: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18),
  );

  void _handleVisibleEndCountChanged(int value) {
    if (!mounted || _visibleEndCount == value) return;
    setState(() => _visibleEndCount = value);
  }
}

class _HeaderLayoutParentData extends ContainerBoxParentData<RenderBox> {
  bool isVisible = true;
}

class _HeaderLayout extends MultiChildRenderObjectWidget {
  const _HeaderLayout({
    required this.beforeTitleCount,
    required this.afterTitleCount,
    required this.endCount,
    required this.textDirection,
    required this.onVisibleEndCountChanged,
    required super.children,
  });

  final int beforeTitleCount;
  final int afterTitleCount;
  final int endCount;
  final TextDirection textDirection;
  final ValueChanged<int> onVisibleEndCountChanged;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeaderLayout(
    beforeTitleCount: beforeTitleCount,
    afterTitleCount: afterTitleCount,
    endCount: endCount,
    textDirection: textDirection,
    onVisibleEndCountChanged: onVisibleEndCountChanged,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderHeaderLayout renderObject,
  ) {
    renderObject
      ..beforeTitleCount = beforeTitleCount
      ..afterTitleCount = afterTitleCount
      ..endCount = endCount
      ..textDirection = textDirection
      ..onVisibleEndCountChanged = onVisibleEndCountChanged;
  }
}

class _RenderHeaderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderLayoutParentData> {
  _RenderHeaderLayout({
    required int beforeTitleCount,
    required int afterTitleCount,
    required int endCount,
    required TextDirection textDirection,
    required this.onVisibleEndCountChanged,
  }) : _beforeTitleCount = beforeTitleCount,
       _afterTitleCount = afterTitleCount,
       _endCount = endCount,
       _textDirection = textDirection;

  int _beforeTitleCount;
  int get beforeTitleCount => _beforeTitleCount;
  set beforeTitleCount(int value) {
    if (_beforeTitleCount == value) return;
    _beforeTitleCount = value;
    markNeedsLayout();
  }

  int _afterTitleCount;
  int get afterTitleCount => _afterTitleCount;
  set afterTitleCount(int value) {
    if (_afterTitleCount == value) return;
    _afterTitleCount = value;
    markNeedsLayout();
  }

  int _endCount;
  int get endCount => _endCount;
  set endCount(int value) {
    if (_endCount == value) return;
    _endCount = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  ValueChanged<int> onVisibleEndCountChanged;

  int? _reportedVisibleEndCount;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _HeaderLayoutParentData) {
      child.parentData = _HeaderLayoutParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    assert(
      children.length ==
          beforeTitleCount +
              1 +
              afterTitleCount +
              endCount +
              (endCount > 0 ? 1 : 0),
    );
    final titleIndex = beforeTitleCount;
    final afterTitleStart = titleIndex + 1;
    final endStart = afterTitleStart + afterTitleCount;
    final overflowIndex = endStart + endCount;
    final childConstraints = constraints.loosen();
    final title = children[titleIndex];

    var fixedWidth = 0.0;
    var maxHeight = 0.0;
    for (var index = 0; index < children.length; index++) {
      if (index == titleIndex) continue;
      final child = children[index]
        ..layout(childConstraints, parentUsesSize: true);
      maxHeight = math.max(maxHeight, child.size.height);
      if (index < endStart) fixedWidth += child.size.width;
    }

    final endWidth = children
        .skip(endStart)
        .take(endCount)
        .map((child) => child.size.width)
        .sum;
    if (!constraints.hasBoundedWidth) {
      title.layout(childConstraints, parentUsesSize: true);
      maxHeight = math.max(maxHeight, title.size.height);
    }
    final availableWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : fixedWidth + endWidth + title.size.width;
    final overflowWidth = endCount > 0 ? children[overflowIndex].size.width : 0;
    final showOverflow = fixedWidth + endWidth > availableWidth;
    final inlineBudget = math.max(
      availableWidth - fixedWidth - (showOverflow ? overflowWidth : 0),
      0.0,
    );
    var visibleEndCount = 0;
    var visibleEndWidth = 0.0;
    for (final child in children.skip(endStart).take(endCount)) {
      if (visibleEndWidth + child.size.width > inlineBudget) break;
      visibleEndWidth += child.size.width;
      visibleEndCount++;
    }
    if (!showOverflow) visibleEndCount = endCount;

    final titleWidth = math.max(
      availableWidth -
          fixedWidth -
          visibleEndWidth -
          (showOverflow ? overflowWidth : 0),
      0.0,
    );
    title.layout(
      childConstraints.copyWith(maxWidth: titleWidth),
      parentUsesSize: true,
    );
    maxHeight = math.max(maxHeight, title.size.height);
    size = constraints.constrain(Size(availableWidth, maxHeight));

    var logicalOffset = 0.0;
    var semanticsChanged = false;
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final parentData = child.parentData! as _HeaderLayoutParentData;
      final isVisible = switch (index) {
        _ when index < endStart => true,
        _ when index < overflowIndex => index - endStart < visibleEndCount,
        _ => showOverflow,
      };
      if (parentData.isVisible != isVisible) {
        parentData.isVisible = isVisible;
        semanticsChanged = true;
      }
      if (!parentData.isVisible) continue;

      final allocatedWidth = index == titleIndex
          ? titleWidth
          : child.size.width;
      final childX = switch (textDirection) {
        TextDirection.ltr => logicalOffset,
        TextDirection.rtl => size.width - logicalOffset - child.size.width,
      };
      parentData.offset = Offset(childX, (size.height - child.size.height) / 2);
      logicalOffset += allocatedWidth;
    }
    if (semanticsChanged) markNeedsSemanticsUpdate();
    _reportVisibleEndCount(visibleEndCount);
  }

  void _reportVisibleEndCount(int value) {
    if (_reportedVisibleEndCount == value) return;
    _reportedVisibleEndCount = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!attached || _reportedVisibleEndCount != value) return;
      onVisibleEndCountChanged(value);
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _HeaderLayoutParentData;
      if (parentData.isVisible) {
        context.paintChild(child, parentData.offset + offset);
      }
      child = childAfter(child);
    }
  }

  @override
  bool paintsChild(RenderBox child) =>
      (child.parentData! as _HeaderLayoutParentData).isVisible;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as _HeaderLayoutParentData;
      if (parentData.isVisible &&
          result.addWithPaintOffset(
            offset: parentData.offset,
            position: position,
            hitTest: (result, transformed) =>
                child!.hitTest(result, position: transformed),
          )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _HeaderLayoutParentData;
      if (parentData.isVisible) visitor(child);
      child = childAfter(child);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as _HeaderLayoutParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }
}

extension on _ResolvedHeaderItem {
  List<ActionShortcut> shortcuts(
    BuildContext context,
    PresentationRenderScope scope,
  ) {
    return switch (this) {
      _ResolvedHeaderButtonItem() || _ResolvedHeaderBooleanToggleItem() => [
        _activationShortcut(context, scope),
      ],
      _ResolvedHeaderReorderHandleItem() => [
        _reorderShortcut(scope, HeaderItemCommand.moveBefore),
        _reorderShortcut(scope, HeaderItemCommand.moveAfter),
        _reorderShortcut(scope, HeaderItemCommand.moveToStart),
        _reorderShortcut(scope, HeaderItemCommand.moveToEnd),
      ],
    };
  }

  ActionShortcut _activationShortcut(
    BuildContext context,
    PresentationRenderScope scope,
  ) {
    final item = this;
    final icon = switch (item) {
      _ResolvedHeaderButtonItem(:final icon) => Icones.value(icon),
      _ResolvedHeaderBooleanToggleItem(:final checked) => Icones(
        checked ? Ic.baseline_check_box : Ic.baseline_check_box_outline_blank,
      ),
      _ => throw StateError("Only activatable header items have shortcuts"),
    };
    return ActionShortcut(
      id: "${id.qualified}:${HeaderItemCommand.activate.name}",
      label: label,
      description: tooltip,
      activators: scope.shortcuts(id, HeaderItemCommand.activate),
      priority: priority,
      icon: icon,
      onInvoke: enabled ? (ref) => _invoke(context, scope) : null,
    );
  }

  ActionShortcut _reorderShortcut(
    PresentationRenderScope scope,
    HeaderItemCommand command,
  ) {
    final item = this as _ResolvedHeaderReorderHandleItem;
    final available = item.enabled && item._destination(command) != null;
    return ActionShortcut(
      id: "${item.id.qualified}:${command.name}",
      label: item._commandLabel(command),
      description: item.tooltip,
      activators: scope.shortcuts(item.id, command),
      priority: 0,
      icon: const Icones(Fa6Solid.bars_staggered),
      onInvoke: available ? (ref) => item._move(scope, command) : null,
    );
  }

  Widget inlineWidget(BuildContext context, PresentationRenderScope scope) {
    return switch (this) {
      _ResolvedHeaderButtonItem(:final icon, :final tone) => IconButton(
        tooltip: tooltip,
        onPressed: enabled ? () => _invoke(context, scope) : null,
        color: tone == HeaderActionTone.destructive
            ? Theme.of(context).colorScheme.error
            : null,
        icon: Icones.value(icon),
      ),
      _ResolvedHeaderBooleanToggleItem(:final checked) => Tooltip(
        message: tooltip,
        child: Checkbox(
          value: checked,
          onChanged: enabled ? (_) => _invoke(context, scope) : null,
          visualDensity: VisualDensity.compact,
          semanticLabel: label,
        ),
      ),
      _ResolvedHeaderReorderHandleItem(:final index) => Tooltip(
        message: tooltip,
        child: ReorderableDragStartListener(
          index: index,
          enabled: enabled,
          child: const SizedBox.square(
            dimension: 40,
            child: Center(child: Icones(Fa6Solid.bars_staggered, size: 18)),
          ),
        ),
      ),
    };
  }

  MenuItem overflowItem(BuildContext context, PresentationRenderScope scope) {
    return switch (this) {
      _ResolvedHeaderButtonItem(:final icon, :final tone) => MenuItem(
        label: label,
        icon: Icones.value(icon, size: 18),
        color: tone == HeaderActionTone.destructive
            ? Theme.of(context).colorScheme.error
            : null,
        shortcuts: scope.shortcuts(id, HeaderItemCommand.activate),
        onPressed: enabled ? () => _invoke(context, scope) : null,
      ),
      _ResolvedHeaderBooleanToggleItem(:final checked) => MenuItem(
        label: label,
        icon: Icones(
          checked ? Ic.baseline_check_box : Ic.baseline_check_box_outline_blank,
          size: 18,
        ),
        shortcuts: scope.shortcuts(id, HeaderItemCommand.activate),
        onPressed: enabled ? () => _invoke(context, scope) : null,
      ),
      _ResolvedHeaderReorderHandleItem() => throw StateError(
        "Reorder handles cannot overflow",
      ),
    };
  }

  Future<void> _invoke(
    BuildContext context,
    PresentationRenderScope scope,
  ) async {
    if (!enabled) return;
    final action = switch (this) {
      _ResolvedHeaderButtonItem(:final action) ||
      _ResolvedHeaderBooleanToggleItem(:final action) => action,
      _ResolvedHeaderReorderHandleItem() => null,
    };
    if (action == null) return;
    if (!await _confirm(context)) return;
    scope.invoke(action);
  }

  Future<bool> _confirm(BuildContext context) async {
    final confirmation = switch (this) {
      _ResolvedHeaderButtonItem(:final confirmation) ||
      _ResolvedHeaderBooleanToggleItem(:final confirmation) => confirmation,
      _ResolvedHeaderReorderHandleItem() => null,
    };
    if (confirmation == null) return true;
    final tone = switch (this) {
      _ResolvedHeaderButtonItem(:final tone) => tone,
      _ => HeaderActionTone.neutral,
    };
    final colorScheme = Theme.of(context).colorScheme;
    return showConfirmationDialogue(
      context: context,
      title: confirmation.title,
      content: confirmation.message,
      confirmText: confirmation.confirmationLabel,
      confirmColor: tone == HeaderActionTone.destructive
          ? colorScheme.error
          : colorScheme.primary,
      onConfirmColor: tone == HeaderActionTone.destructive
          ? colorScheme.onError
          : colorScheme.onPrimary,
    );
  }
}

extension on List<_ResolvedHeaderItem> {
  List<_ResolvedHeaderItem> at(HeaderActionPlacement placement) =>
      [
        for (final item in this)
          if (item.placement == placement) item,
      ]..sort((left, right) {
        final priority = right.priority.compareTo(left.priority);
        return priority != 0
            ? priority
            : left.declarationOrder.compareTo(right.declarationOrder);
      });
}

class _OverflowItems extends StatelessWidget {
  const _OverflowItems({required this.items, required this.scope});

  final List<_ResolvedHeaderItem> items;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) => ContextMenuRegion(
    enableGestures: false,
    items: [for (final item in items) item.overflowItem(context, scope)],
    builder: (context, controller, child) => IconButton(
      tooltip: "More actions",
      onPressed: ContextMenuRegion.onPress(controller),
      icon: const Icones(Fa6Solid.ellipsis),
    ),
  );
}
