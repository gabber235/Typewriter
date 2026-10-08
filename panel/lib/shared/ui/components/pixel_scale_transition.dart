import "package:typewriter_panel/typewriter_panel.dart";

/// Adds an animated pixel amount to a child's scale.
///
/// The child is measured after its first frame and the [pixelScale] value is
/// converted using the child's longest side. Until measurement is available,
/// and for zero sized children, the child is rendered at its original scale.
/// The widget remeasures when the animation object changes, so the animation
/// and child can be rebuilt without transferring measurement state manually.
/// [origin] and [alignment] retain the same meaning as [Transform.scale].
class PixelScaleTransition extends StatefulWidget {
  const PixelScaleTransition({
    required this.child,
    required this.pixelScale,
    this.origin = Offset.zero,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;
  final Animation<double> pixelScale;
  final Offset origin;
  final Alignment alignment;

  @override
  State<PixelScaleTransition> createState() => _PixelScaleTransitionState();
}

class _PixelScaleTransitionState extends State<PixelScaleTransition> {
  final _childKey = GlobalKey();
  Size? _childSize;

  void _measureChild() {
    final context = _childKey.currentContext;
    if (context == null) return;

    final size = context.size;
    if (_childSize == size) return;

    setState(() {
      _childSize = size;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChild();
    });
  }

  @override
  void didUpdateWidget(covariant PixelScaleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pixelScale != oldWidget.pixelScale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureChild();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pixelScale,
      child: KeyedSubtree(key: _childKey, child: widget.child),
      builder: (context, child) {
        if (_childSize == null) return _scale(child: child);
        final pixels = widget.pixelScale.value;
        final longestSide = _childSize!.longestSide;
        if (longestSide == 0) return _scale(child: child);
        final scale = (longestSide + pixels) / longestSide;
        return _scale(scale: scale, child: child);
      },
    );
  }

  Widget _scale({required Widget? child, double scale = 1}) {
    return Transform.scale(
      scale: scale,
      origin: widget.origin,
      alignment: widget.alignment,
      child: child,
    );
  }
}
