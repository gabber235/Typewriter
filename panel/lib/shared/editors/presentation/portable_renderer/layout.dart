part of "../portable_presentation_renderer.dart";

extension _PortableLayoutRendering on PortablePresentationNodeRenderer {
  Widget _renderChildren(
    skir.ChildrenElement element,
    PortablePresentationScope childScope, {
    required bool fillAvailableSpace,
  }) => switch (element) {
    skir.ChildrenElement_columnWrapper(:final value) => _axis(
      value,
      childScope,
      vertical: true,
      fillAvailableSpace: fillAvailableSpace,
    ),
    skir.ChildrenElement_rowWrapper(:final value) => _axis(
      value,
      childScope,
      vertical: false,
      fillAvailableSpace: fillAvailableSpace,
    ),
    skir.ChildrenElement_wrapWrapper(:final value) => Wrap(
      spacing: value.layout.spacing,
      runSpacing: value.layout.runSpacing,
      alignment: _wrapAlignment(value.layout.mainAxisAlignment),
      crossAxisAlignment: _wrapCrossAlignment(value.layout.crossAxisAlignment),
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    skir.ChildrenElement_gridWrapper(:final value) => _presentationGrid(
      value.layout,
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    skir.ChildrenElement_stackWrapper(:final value) => Stack(
      children: [
        for (final child in value.children)
          PortablePresentationNodeRenderer(node: child, scope: childScope),
      ],
    ),
    _ => _diagnostic("Children layout ${element.kind.name} is not implemented"),
  };

  Widget _axis(
    skir.AxisChildrenElement element,
    PortablePresentationScope childScope, {
    required bool vertical,
    required bool fillAvailableSpace,
  }) {
    Widget buildAxis(double? fixedChildMaximumHeight) {
      final children = <Widget>[];
      final forwardsViewport =
          vertical && fillAvailableSpace && element.children.length == 1;
      var first = true;
      for (final child in element.children) {
        if (!first && element.layout.spacing > 0) {
          children.add(
            SizedBox(
              width: vertical ? null : element.layout.spacing,
              height: vertical ? element.layout.spacing : null,
            ),
          );
        }
        first = false;
        var rendered = switch (child) {
          skir.AxisChild_fixedWrapper(:final value) =>
            PortablePresentationNodeRenderer(node: value, scope: childScope),
          skir.AxisChild_flexibleWrapper(:final value) => Flexible(
            flex: value.flex <= 0 ? 1 : value.flex,
            fit: value.fit == skir.FlexFit.tight
                ? FlexFit.tight
                : FlexFit.loose,
            child: PortablePresentationNodeRenderer(
              node: value.child,
              scope: childScope,
            ),
          ),
          _ => _diagnostic("The axis child is unknown"),
        };
        if (fixedChildMaximumHeight != null &&
            child is skir.AxisChild_fixedWrapper) {
          rendered = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: fixedChildMaximumHeight),
            child: rendered,
          );
        }
        children.add(
          forwardsViewport && child is skir.AxisChild_fixedWrapper
              ? Expanded(child: rendered)
              : rendered,
        );
      }
      if (vertical) {
        return Column(
          mainAxisSize: fillAvailableSpace
              ? MainAxisSize.max
              : MainAxisSize.min,
          mainAxisAlignment: _mainAxis(element.layout.mainAxisAlignment),
          crossAxisAlignment: _crossAxis(element.layout.crossAxisAlignment),
          children: children,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: _mainAxis(element.layout.mainAxisAlignment),
        crossAxisAlignment: _crossAxis(element.layout.crossAxisAlignment),
        children: children,
      );
    }

    if (!vertical || element.children.length != 1) return buildAxis(null);
    return LayoutBuilder(
      builder: (context, constraints) => buildAxis(
        constraints.hasBoundedHeight ? constraints.maxHeight : null,
      ),
    );
  }

  Widget _renderConditional(
    skir.ConditionalElement element,
    PortablePresentationScope childScope,
  ) {
    final condition = _boolean(childScope, element.condition);
    return switch (condition) {
      _ResolvedValue(value: true) => PortablePresentationNodeRenderer(
        node: element.whenTrue,
        scope: childScope,
      ),
      _ResolvedValue(value: false) when element.whenFalse != null =>
        PortablePresentationNodeRenderer(
          node: element.whenFalse!,
          scope: childScope,
        ),
      _ResolvedValue() => const SizedBox.shrink(),
      _ResolvedFailure(:final message) => _diagnostic(message),
    };
  }

  Widget _renderRepeated(
    skir.RepeatedElement element,
    PortablePresentationScope childScope,
  ) {
    final evaluated = childScope.evaluate(element.source);
    if (evaluated is! PortableExpressionAvailable) {
      return _diagnostic("The repeated value is unavailable");
    }
    final rows = switch (evaluated.value.authoredPayload) {
      skir.DataValue_listValueWrapper(:final value) ||
      skir.DataValue_setValueWrapper(:final value) => [
        for (final item in value.items)
          (id: item.id, value: item.value, mapValue: false),
      ],
      skir.DataValue_mapValueWrapper(:final value) => [
        for (final row in value.rows)
          (id: row.id, value: row.value, mapValue: true),
      ],
      _ => null,
    };
    if (rows == null) {
      return _diagnostic("The repeated value is not a collection");
    }
    if (rows.isEmpty) {
      final empty = element.presentation.empty;
      return empty == null
          ? const SizedBox.shrink()
          : PortablePresentationNodeRenderer(node: empty, scope: childScope);
    }
    final children = <Widget>[];
    final itemScopes = <PortablePresentationScope>[];
    final source = switch (element.source) {
      skir.ExpressionNode_readWrapper(:final value) => skir.BindingRef(
        bindingId: value.binding,
        path: value.path,
      ),
      _ => null,
    };
    for (final indexed in rows.indexed) {
      if (indexed.$1 > 0 && element.presentation.separator != null) {
        children.add(
          PortablePresentationNodeRenderer(
            node: element.presentation.separator!,
            scope: childScope,
          ),
        );
        itemScopes.add(childScope);
      }
      final row = indexed.$2;
      final rowReference = source == null
          ? null
          : skir.BindingRef(
              bindingId: source.bindingId,
              path: skir.ValuePath(
                segments: [
                  ...source.path.segments,
                  skir.PathSegment.createItem(id: row.id),
                  if (row.mapValue) skir.PathSegment.mapValue,
                ],
              ),
            );
      final itemScope = rowReference == null
          ? childScope.withValues({element.itemBindingId: row.value})
          : childScope.withBinding(rowReference, element.itemBindingId);
      children.add(
        itemScope == null
            ? _diagnostic("The repeated collection item is unavailable")
            : PortablePresentationNodeRenderer(
                node: element.presentation.item,
                scope: itemScope,
              ),
      );
      itemScopes.add(itemScope ?? childScope);
    }
    return _renderSequence(
      children,
      element.presentation.layout,
      childScope,
      itemScopes: itemScopes,
    );
  }

  Widget _renderSequence(
    List<Widget> children,
    skir.SequenceLayout layout,
    PortablePresentationScope childScope, {
    List<PortablePresentationScope>? itemScopes,
  }) => switch (layout) {
    skir.SequenceLayout_childrenWrapper(:final value) =>
      _renderSequenceChildren(children, value),
    skir.SequenceLayout_hierarchyWrapper(:final value) =>
      value.renderPortableHierarchy(
        scope: childScope,
        itemScopes: itemScopes ?? List.filled(children.length, childScope),
        children: children,
      ),
    _ => _diagnostic("The sequence layout is unavailable"),
  };

  Widget _renderSequenceChildren(
    List<Widget> children,
    skir.ChildrenLayout layout,
  ) => switch (layout) {
    skir.ChildrenLayout_columnWrapper(:final value) => Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _mainAxis(value.mainAxisAlignment),
      crossAxisAlignment: _crossAxis(value.crossAxisAlignment),
      spacing: value.spacing,
      children: children,
    ),
    skir.ChildrenLayout_rowWrapper(:final value) => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _mainAxis(value.mainAxisAlignment),
      crossAxisAlignment: _crossAxis(value.crossAxisAlignment),
      spacing: value.spacing,
      children: children,
    ),
    skir.ChildrenLayout_wrapWrapper(:final value) => Wrap(
      spacing: value.spacing,
      runSpacing: value.runSpacing,
      alignment: _wrapAlignment(value.mainAxisAlignment),
      crossAxisAlignment: _wrapCrossAlignment(value.crossAxisAlignment),
      children: children,
    ),
    skir.ChildrenLayout_gridWrapper(:final value) => _presentationGrid(
      value,
      children: children,
    ),
    skir.ChildrenLayout.stack => Stack(children: children),
    _ => _diagnostic("The repeated children layout is unavailable"),
  };

  Widget _renderAdaptiveLeading(
    skir.AdaptiveLeadingElement element,
    PortablePresentationScope childScope,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth) {
        return _diagnostic("Adaptive leading requires finite maximum width");
      }
      return AdaptiveLeadingLayout(
        leading: PortablePresentationNodeRenderer(
          node: element.leading,
          scope: childScope,
        ),
        center: element.center == null
            ? null
            : PortablePresentationNodeRenderer(
                node: element.center!,
                scope: childScope,
              ),
        suffix: element.suffix == null
            ? null
            : PortablePresentationNodeRenderer(
                node: element.suffix!,
                scope: childScope,
              ),
        padding: _presentationInsets(element.padding),
        compactPadding: _presentationInsets(element.compactPadding),
        gap: element.gap,
        minCenterWidth: element.minimumCenterWidth,
      );
    },
  );

  Widget _renderContainer(
    BuildContext context,
    skir.ContainerLayout container,
    PortablePresentationScope childScope,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: _color(childScope, container.backgroundColor),
      border: _border(context, container.border, childScope),
      borderRadius: _radius(context, container.radius, childScope),
    ),
    child: PortablePresentationNodeRenderer(
      node: container.child,
      scope: childScope,
    ),
  );

  Widget _renderSection(
    BuildContext context,
    skir.SectionLayout section,
    PortablePresentationScope childScope,
  ) {
    return PortablePresentationNodeRenderer(
      node: section.child,
      scope: childScope,
    );
  }

  Widget _decorateSection(
    BuildContext context,
    skir.SectionLayout section,
    PortablePresentationScope childScope,
    Widget child,
  ) {
    final border = _border(context, section.border, childScope);
    return DepthBox(
      child: border == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(
                border: border,
                borderRadius: context.shapes.mediumBorderRadius,
              ),
              child: child,
            ),
    );
  }

  Widget _renderSpacer(
    skir.SpacerLayout spacer,
    PortablePresentationScope childScope,
  ) => SizedBox(
    width: _number(childScope, spacer.width),
    height: _number(childScope, spacer.height),
  );
}

final class _AuthoredTabs extends StatefulWidget {
  const _AuthoredTabs({required this.tabs, required this.scope});

  final skir.TabsLayout tabs;
  final PortablePresentationScope scope;

  @override
  State<_AuthoredTabs> createState() => _AuthoredTabsState();
}

final class _AuthoredTabsState extends State<_AuthoredTabs> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
  }

  @override
  void didUpdateWidget(covariant _AuthoredTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.tabs.every((tab) => tab.tabId != _selected)) {
      _selected = _initialSelection();
    }
  }

  String? _initialSelection() {
    final requested = widget.tabs.initiallySelectedTabId;
    if (requested != null &&
        widget.tabs.tabs.any((tab) => tab.tabId == requested)) {
      return requested;
    }
    return widget.tabs.tabs.firstOrNull?.tabId;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs.tabs.toList(growable: false);
    if (tabs.isEmpty) return _diagnostic("The tab layout has no tabs");
    final selected = tabs.firstWhere(
      (tab) => tab.tabId == _selected,
      orElse: () => tabs.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: context.spacing.space2,
          children: [
            for (final tab in tabs)
              ChoiceChip(
                selected: tab.tabId == selected.tabId,
                label: switch (_string(widget.scope, tab.label)) {
                  _ResolvedValue(:final value) => Text(value),
                  _ResolvedFailure() => Text(tab.tabId),
                },
                onSelected: widget.scope.enabled
                    ? (_) => setState(() => _selected = tab.tabId)
                    : null,
              ),
          ],
        ),
        SizedBox(height: context.spacing.space2),
        PortablePresentationNodeRenderer(
          node: selected.child,
          scope: widget.scope,
        ),
      ],
    );
  }
}

MainAxisAlignment _mainAxis(skir.MainAxisAlignment value) => switch (value) {
  skir.MainAxisAlignment.center => MainAxisAlignment.center,
  skir.MainAxisAlignment.end => MainAxisAlignment.end,
  skir.MainAxisAlignment.spaceBetween => MainAxisAlignment.spaceBetween,
  skir.MainAxisAlignment.spaceAround => MainAxisAlignment.spaceAround,
  skir.MainAxisAlignment.spaceEvenly => MainAxisAlignment.spaceEvenly,
  _ => MainAxisAlignment.start,
};

CrossAxisAlignment _crossAxis(skir.CrossAxisAlignment value) => switch (value) {
  skir.CrossAxisAlignment.center => CrossAxisAlignment.center,
  skir.CrossAxisAlignment.end => CrossAxisAlignment.end,
  skir.CrossAxisAlignment.stretch => CrossAxisAlignment.stretch,
  _ => CrossAxisAlignment.start,
};

WrapAlignment _wrapAlignment(skir.MainAxisAlignment value) => switch (value) {
  skir.MainAxisAlignment.center => WrapAlignment.center,
  skir.MainAxisAlignment.end => WrapAlignment.end,
  skir.MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
  skir.MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
  skir.MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
  _ => WrapAlignment.start,
};

WrapCrossAlignment _wrapCrossAlignment(skir.CrossAxisAlignment value) =>
    switch (value) {
      skir.CrossAxisAlignment.center => WrapCrossAlignment.center,
      skir.CrossAxisAlignment.end => WrapCrossAlignment.end,
      _ => WrapCrossAlignment.start,
    };

Widget _presentationGrid(
  skir.GridChildrenLayout layout, {
  required List<Widget> children,
}) => LayoutBuilder(
  builder: (context, constraints) {
    if (!constraints.hasBoundedWidth) {
      return Wrap(
        spacing: layout.horizontalSpacing,
        runSpacing: layout.verticalSpacing,
        children: children,
      );
    }
    final columns = layout.columns < 1 ? 1 : layout.columns;
    final width =
        ((constraints.maxWidth - layout.horizontalSpacing * (columns - 1)) /
                columns)
            .clamp(0.0, constraints.maxWidth);
    return Wrap(
      spacing: layout.horizontalSpacing,
      runSpacing: layout.verticalSpacing,
      children: [
        for (final child in children) SizedBox(width: width, child: child),
      ],
    );
  },
);
