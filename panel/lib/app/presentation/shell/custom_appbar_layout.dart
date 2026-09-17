import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

/// Child roles supported by [CustomAppBarLayout].
enum CustomAppBarSlot {
  leading,
  search,
  trailing,
  compactSearch,
  compactTrailing,
}

/// Selects and positions full or compact app bar content from measured sizes.
///
/// The full search stays centered while space permits. Asymmetric leading or
/// trailing content moves it only far enough to preserve [spacing]. When the
/// full slots do not fit, the compact slots replace them and [leading] receives
/// the remaining width.
class CustomAppBarLayout
    extends SlottedMultiChildRenderObjectWidget<CustomAppBarSlot, RenderBox> {
  const CustomAppBarLayout({
    required this.leading,
    required this.search,
    required this.trailing,
    required this.compactSearch,
    required this.compactTrailing,
    required this.spacing,
    super.key,
  });

  final Widget leading;
  final Widget search;
  final Widget trailing;
  final Widget compactSearch;
  final Widget compactTrailing;
  final double spacing;

  @override
  Iterable<CustomAppBarSlot> get slots => CustomAppBarSlot.values;

  @override
  Widget childForSlot(CustomAppBarSlot slot) {
    return switch (slot) {
      CustomAppBarSlot.leading => leading,
      CustomAppBarSlot.search => search,
      CustomAppBarSlot.trailing => trailing,
      CustomAppBarSlot.compactSearch => compactSearch,
      CustomAppBarSlot.compactTrailing => compactTrailing,
    };
  }

  @override
  RenderCustomAppBarLayout createRenderObject(BuildContext context) {
    return RenderCustomAppBarLayout(spacing: spacing);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCustomAppBarLayout renderObject,
  ) {
    renderObject.spacing = spacing;
  }
}

/// Measures and positions the slots owned by [CustomAppBarLayout].
class RenderCustomAppBarLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<CustomAppBarSlot, RenderBox> {
  RenderCustomAppBarLayout({required this._spacing});

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  bool _useCompactSlots = false;

  RenderBox get _leading => childForSlot(CustomAppBarSlot.leading)!;
  RenderBox get _search => childForSlot(CustomAppBarSlot.search)!;
  RenderBox get _trailing => childForSlot(CustomAppBarSlot.trailing)!;
  RenderBox get _compactSearch => childForSlot(CustomAppBarSlot.compactSearch)!;
  RenderBox get _compactTrailing =>
      childForSlot(CustomAppBarSlot.compactTrailing)!;

  RenderBox get _activeSearch => _useCompactSlots ? _compactSearch : _search;
  RenderBox get _activeTrailing =>
      _useCompactSlots ? _compactTrailing : _trailing;

  @override
  void performLayout() {
    size = constraints.biggest;
    final looseConstraints = BoxConstraints.loose(size);

    for (final child in children) {
      child.layout(looseConstraints, parentUsesSize: true);
      (child.parentData! as BoxParentData).offset = Offset.zero;
    }

    _useCompactSlots =
        _requiredWidth(_leading, _search, _trailing) > size.width;

    final activeSearch = _activeSearch;
    final activeTrailing = _activeTrailing;
    final fixedWidth =
        activeSearch.size.width + activeTrailing.size.width + spacing * 2;
    final leadingWidth = (size.width - fixedWidth).clamp(0.0, size.width);
    _leading.layout(
      BoxConstraints(maxWidth: leadingWidth, maxHeight: size.height),
      parentUsesSize: true,
    );

    final leadingRight = _leading.size.width;
    final trailingX = size.width - activeTrailing.size.width;
    final minimumSearchX = leadingRight + spacing;
    final maximumSearchX = trailingX - spacing - activeSearch.size.width;
    final centeredSearchX = (size.width - activeSearch.size.width) / 2;
    final searchX = _useCompactSlots
        ? maximumSearchX
        : maximumSearchX < minimumSearchX
        ? minimumSearchX
        : centeredSearchX.clamp(minimumSearchX, maximumSearchX);

    _position(_leading, 0);
    _position(activeSearch, searchX);
    _position(activeTrailing, trailingX);
  }

  double _requiredWidth(
    RenderBox leading,
    RenderBox search,
    RenderBox trailing,
  ) {
    return leading.size.width +
        search.size.width +
        trailing.size.width +
        spacing * 2;
  }

  void _position(RenderBox child, double x) {
    (child.parentData! as BoxParentData).offset = Offset(
      x,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool paintsChild(RenderBox child) {
    return child == _leading ||
        child == _activeSearch ||
        child == _activeTrailing;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in [_leading, _activeSearch, _activeTrailing]) {
      final parentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + parentData.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_activeTrailing, _activeSearch, _leading]) {
      final parentData = child.parentData! as BoxParentData;
      final hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return child.hitTest(result, position: transformed);
        },
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as BoxParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(_leading);
    visitor(_activeSearch);
    visitor(_activeTrailing);
  }
}
