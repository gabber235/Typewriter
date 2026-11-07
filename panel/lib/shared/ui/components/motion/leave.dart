import "package:typewriter_panel/typewriter_panel.dart";

/// Squashes [child] shut as [progress] goes from 1 to 0: height, vertical
/// scale and opacity go to zero together, so its neighbours close the gap
/// with it. Play `listOut` on the progress. The widgets around [child] are
/// the same at every progress, so a child that starts to leave keeps its
/// state.
class Leave extends StatelessWidget {
  const Leave({required this.progress, required this.child, super.key});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final open = progress.value.clamp(0.0, 1.0);
        return ClipRect(
          clipBehavior: open < 1 ? Clip.hardEdge : Clip.none,
          child: _HeightFactor(
            factor: open,
            child: Transform.scale(
              scaleX: 1,
              scaleY: open,
              child: Opacity(opacity: open, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Lays [child] out as its parent asks and takes [factor] of its height,
/// without loosening the constraints the way Align does.
class _HeightFactor extends SingleChildRenderObjectWidget {
  const _HeightFactor({required this.factor, super.child});

  final double factor;

  @override
  _RenderHeightFactor createRenderObject(BuildContext context) =>
      _RenderHeightFactor(factor);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeightFactor renderObject,
  ) => renderObject.factor = factor;
}

class _RenderHeightFactor extends RenderProxyBox {
  _RenderHeightFactor(this._factor);

  double _factor;
  double get factor => _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsLayout();
  }

  // In place the child sees its parent's constraints unchanged.
  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      _factor >= 1 ? constraints : constraints.copyWith(minHeight: 0);

  Size _sized(BoxConstraints constraints, Size child) =>
      constraints.constrain(Size(child.width, child.height * _factor));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _sized(
      constraints,
      child.getDryLayout(_childConstraints(constraints)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) * _factor;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = _sized(constraints, child.size);
  }
}
