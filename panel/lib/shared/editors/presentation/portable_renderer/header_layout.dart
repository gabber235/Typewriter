part of "../portable_presentation_renderer.dart";

final class _PortableHeaderRow extends StatefulWidget {
  const _PortableHeaderRow({
    required this.before,
    required this.title,
    required this.after,
    required this.end,
  });

  final List<Widget> before;
  final Widget title;
  final List<Widget> after;
  final List<Widget> end;

  @override
  State<_PortableHeaderRow> createState() => _PortableHeaderRowState();
}

final class _PortableHeaderRowState extends State<_PortableHeaderRow> {
  var _visibleEndCount = 0;

  @override
  Widget build(BuildContext context) {
    final overflow = widget.end
        .skip(_visibleEndCount.clamp(0, widget.end.length))
        .toList();
    Widget spaced(Widget child) => Padding(
      padding: EdgeInsetsDirectional.only(end: context.spacing.space2),
      child: child,
    );
    return _PortableHeaderLayout(
      beforeTitleCount: widget.before.length,
      afterTitleCount: widget.after.length,
      endCount: widget.end.length,
      textDirection: Directionality.of(context),
      onVisibleEndCountChanged: (value) {
        if (mounted && _visibleEndCount != value) {
          setState(() => _visibleEndCount = value);
        }
      },
      children: [
        for (final item in widget.before) spaced(item),
        widget.title,
        for (final item in widget.after) spaced(item),
        for (final item in widget.end) spaced(item),
        if (widget.end.isNotEmpty)
          _PortableHeaderOverflow(
            items: overflow.isEmpty ? widget.end : overflow,
          ),
      ],
    );
  }
}

final class _PortableHeaderOverflow extends StatelessWidget {
  const _PortableHeaderOverflow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: [
      for (final item in items)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.space1),
          child: item,
        ),
    ],
    builder: (context, controller, child) => IconButton(
      tooltip: "More actions",
      onPressed: controller.isOpen ? controller.close : controller.open,
      icon: const Icon(Icons.more_horiz),
    ),
  );
}

final class _PortableHeaderParentData
    extends ContainerBoxParentData<RenderBox> {
  bool visible = true;
}

final class _PortableHeaderLayout extends MultiChildRenderObjectWidget {
  const _PortableHeaderLayout({
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
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPortableHeaderLayout(
        beforeTitleCount,
        afterTitleCount,
        endCount,
        textDirection,
        onVisibleEndCountChanged,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPortableHeaderLayout renderObject,
  ) {
    renderObject
      ..beforeTitleCount = beforeTitleCount
      ..afterTitleCount = afterTitleCount
      ..endCount = endCount
      ..textDirection = textDirection
      ..onVisibleEndCountChanged = onVisibleEndCountChanged;
  }
}

final class _RenderPortableHeaderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PortableHeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PortableHeaderParentData> {
  _RenderPortableHeaderLayout(
    this._beforeTitleCount,
    this._afterTitleCount,
    this._endCount,
    this._textDirection,
    this.onVisibleEndCountChanged,
  );

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
    if (child.parentData is! _PortableHeaderParentData) {
      child.parentData = _PortableHeaderParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    final titleIndex = beforeTitleCount;
    final endStart = titleIndex + 1 + afterTitleCount;
    final overflowIndex = endStart + endCount;
    final childConstraints = constraints.loosen();
    final title = children[titleIndex];
    var fixedWidth = 0.0;
    var maxHeight = 0.0;
    for (var index = 0; index < children.length; index++) {
      if (index == titleIndex) continue;
      final child = children[index]
        ..layout(childConstraints, parentUsesSize: true);
      maxHeight = max(maxHeight, child.size.height);
      if (index < endStart) fixedWidth += child.size.width;
    }
    final endWidth = children
        .skip(endStart)
        .take(endCount)
        .fold(0.0, (width, child) => width + child.size.width);
    if (!constraints.hasBoundedWidth) {
      title.layout(childConstraints, parentUsesSize: true);
    }
    final availableWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : fixedWidth + endWidth + title.size.width;
    final overflowWidth = endCount > 0 ? children[overflowIndex].size.width : 0;
    final showOverflow = fixedWidth + endWidth > availableWidth;
    final inlineBudget = max(
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
    final titleWidth = max(
      availableWidth -
          fixedWidth -
          visibleEndWidth -
          (showOverflow ? overflowWidth : 0),
      0.0,
    );
    title.layout(
      childConstraints.copyWith(minWidth: titleWidth, maxWidth: titleWidth),
      parentUsesSize: true,
    );
    maxHeight = max(maxHeight, title.size.height);
    size = constraints.constrain(Size(availableWidth, maxHeight));
    var logicalOffset = 0.0;
    var semanticsChanged = false;
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      final parentData = child.parentData! as _PortableHeaderParentData;
      final visible = switch (index) {
        _ when index < endStart => true,
        _ when index < overflowIndex => index - endStart < visibleEndCount,
        _ => showOverflow,
      };
      if (parentData.visible != visible) {
        parentData.visible = visible;
        semanticsChanged = true;
      }
      if (!visible) continue;
      final allocatedWidth = index == titleIndex
          ? titleWidth
          : child.size.width;
      final x = textDirection == TextDirection.ltr
          ? logicalOffset
          : size.width - logicalOffset - child.size.width;
      parentData.offset = Offset(x, (size.height - child.size.height) / 2);
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
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible) {
        context.paintChild(child, parentData.offset + offset);
      }
      child = childAfter(child);
    }
  }

  @override
  bool paintsChild(RenderBox child) =>
      (child.parentData! as _PortableHeaderParentData).visible;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible &&
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
      final parentData = child.parentData! as _PortableHeaderParentData;
      if (parentData.visible) visitor(child);
      child = childAfter(child);
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as _PortableHeaderParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }
}
