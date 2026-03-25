import "package:flutter/material.dart";

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
        if (longestSide == 0) return _scale(child: child!);
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
