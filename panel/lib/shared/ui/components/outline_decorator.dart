import "package:typewriter_panel/typewriter_panel.dart";

/// Layers built by [OutlineDecorator].
enum OutlineSlot { base, outer, inner }

/// Builds the content used by each outline layer.
typedef OutlineContentBuilder = WidgetBuilder;

/// Paints a base subtree with optional outer and inner outline layers.
///
/// [builder] is invoked separately for the base and each enabled outline so
/// the same conceptual content can be painted more than once without reusing a
/// widget instance. The base layer owns layout and hit testing; outline layers
/// are painted only and do not determine the widget's size. [show] disables both
/// outline layers while retaining the base subtree.
///
/// Use this instead of a separate foreground overlay when the outlined content
/// must remain the single layout and interaction owner. The builder must be
/// safe to invoke once per enabled layer.
class OutlineDecorator
    extends SlottedMultiChildRenderObjectWidget<OutlineSlot, RenderBox> {
  const OutlineDecorator({
    required this.show,
    required this.outerColor,
    required this.builder,
    this.innerColor,
    this.outerThickness = 5.5,
    this.innerThickness = 2.5,
    super.key,
  });

  final bool show;

  final OutlineContentBuilder builder;

  final Color outerColor;
  final double outerThickness;

  final Color? innerColor;
  final double innerThickness;

  @override
  Iterable<OutlineSlot> get slots => OutlineSlot.values;

  @override
  Widget? childForSlot(OutlineSlot slot) {
    switch (slot) {
      case OutlineSlot.base:
        return Builder(builder: builder);
      case OutlineSlot.outer:
        if (!show || outerThickness <= 0) return null;
        return Builder(builder: builder);
      case OutlineSlot.inner:
        if (!show || innerColor == null || innerThickness <= 0) return null;
        return Builder(builder: builder);
    }
  }

  @override
  SlottedContainerRenderObjectMixin<OutlineSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderOutlineDecorator(
      show: show,
      outerColor: outerColor,
      innerColor: innerColor,
      outerThickness: outerThickness,
      innerThickness: innerThickness,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    covariant _RenderOutlineDecorator renderObject,
  ) {
    renderObject
      ..show = show
      ..outerColor = outerColor
      ..innerColor = innerColor
      ..outerThickness = outerThickness
      ..innerThickness = innerThickness;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty("show", value: show, ifTrue: "showing", ifFalse: "hidden"),
      )
      ..add(ColorProperty("outerColor", outerColor))
      ..add(DoubleProperty("outerThickness", outerThickness))
      ..add(ColorProperty("innerColor", innerColor))
      ..add(DoubleProperty("innerThickness", innerThickness));
  }
}

class _RenderOutlineDecorator extends RenderBox
    with SlottedContainerRenderObjectMixin<OutlineSlot, RenderBox> {
  _RenderOutlineDecorator({
    required this._show,
    required this._outerColor,
    required this._innerColor,
    required this._outerThickness,
    required this._innerThickness,
  });

  bool get show => _show;
  bool _show;
  set show(bool value) {
    if (value == _show) return;
    _show = value;
    markNeedsPaint();
  }

  Color get outerColor => _outerColor;
  Color _outerColor;
  set outerColor(Color value) {
    if (value == _outerColor) return;
    _outerColor = value;
    markNeedsPaint();
  }

  Color? get innerColor => _innerColor;
  Color? _innerColor;
  set innerColor(Color? value) {
    if (value == _innerColor) return;
    _innerColor = value;
    markNeedsPaint();
  }

  double get outerThickness => _outerThickness;
  double _outerThickness;
  set outerThickness(double value) {
    if (value == _outerThickness) return;
    _outerThickness = value;
    markNeedsPaint();
  }

  double get innerThickness => _innerThickness;
  double _innerThickness;
  set innerThickness(double value) {
    if (value == _innerThickness) return;
    _innerThickness = value;
    markNeedsPaint();
  }

  RenderBox? get _baseChild => childForSlot(OutlineSlot.base);
  RenderBox? get _outerChild => childForSlot(OutlineSlot.outer);
  RenderBox? get _innerChild => childForSlot(OutlineSlot.inner);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    final base = _baseChild;
    if (base == null) {
      size = constraints.smallest;
      return;
    }

    base.layout(constraints, parentUsesSize: true);
    size = base.size;

    final outer = _outerChild;
    if (outer != null) {
      outer.layout(constraints, parentUsesSize: false);
    }

    final inner = _innerChild;
    if (inner != null) {
      inner.layout(constraints, parentUsesSize: false);
    }
  }

  double _scaleFor(double thickness, double extent) {
    if (thickness <= 0 || extent <= 0) return 1.0;
    return 1.0 + (2.0 * thickness) / extent;
  }

  Matrix4 _centerScaleMatrix(Size s, double thickness) {
    final sx = _scaleFor(thickness, s.width);
    final sy = _scaleFor(thickness, s.height);
    final cx = s.width / 2.0;
    final cy = s.height / 2.0;
    final m = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
    return m;
  }

  void _paintLayer({
    required PaintingContext context,
    required Offset offset,
    required RenderBox child,
    required double thickness,
    required Color color,
  }) {
    if (thickness <= 0) return;
    final transform = _centerScaleMatrix(size, thickness);
    context.pushTransform(true, offset, transform, (inner, innerOffset) {
      inner.pushColorFilter(
        innerOffset,
        ColorFilter.mode(color, BlendMode.srcIn),
        (colorContext, colorOffset) {
          colorContext.paintChild(child, colorOffset);
        },
      );
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final base = _baseChild;
    if (base == null) return;

    if (show) {
      final outer = _outerChild;
      if (outer != null) {
        _paintLayer(
          context: context,
          offset: offset,
          child: outer,
          thickness: outerThickness,
          color: outerColor,
        );
      }

      final inner = _innerChild;
      if (inner != null && innerColor != null && innerThickness > 0) {
        _paintLayer(
          context: context,
          offset: offset,
          child: inner,
          thickness: innerThickness,
          color: innerColor!,
        );
      }
    }

    context.paintChild(base, offset);
  }

  @override
  bool get alwaysNeedsCompositing {
    if (!show) return false;
    return _outerChild != null || _innerChild != null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final base = _baseChild;
    if (base == null) return false;
    final parentData = base.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (res, transformed) => base.hitTest(res, position: transformed),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        FlagProperty("show", value: show, ifTrue: "showing", ifFalse: "hidden"),
      )
      ..add(ColorProperty("outerColor", outerColor))
      ..add(DoubleProperty("outerThickness", outerThickness))
      ..add(ColorProperty("innerColor", innerColor))
      ..add(DoubleProperty("innerThickness", innerThickness));
  }
}
