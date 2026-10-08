import "package:typewriter_panel/typewriter_panel.dart";

/// Creates the theme derived gradient used by [Shimmer].
///
/// Explicit colors override the corresponding theme colors. The gradient is
/// translated by [ShimmerState] while at least one descendant is registered.
LinearGradient createShimmerGradient(
  BuildContext context, {
  Color? baseColor,
  Color? highlightColor,
}) {
  baseColor ??= Color.alphaBlend(
    Theme.of(context).inputDecorationTheme.fillColor ??
        Theme.of(context).colorScheme.surfaceContainerLowest,
    Theme.of(context).scaffoldBackgroundColor,
  );
  highlightColor ??= Theme.of(context).colorScheme.surfaceContainerLowest;

  return LinearGradient(
    colors: [baseColor, highlightColor, baseColor],
    stops: const [0.1, 0.3, 0.4],
    begin: const Alignment(-1.0, -0.3),
    end: const Alignment(1.0, 0.3),
    tileMode: TileMode.clamp,
  );
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// A widget that provides shimmer animation to its descendants.
///
/// Wrap this around a section of your UI where you want to apply
/// shimmer effects to loading states.
/// Owns one shimmer timeline shared by registered loading descendants.
///
/// Wrap a loading region with this widget, then use [ShimmerLoading] for each
/// placeholder that should move with the same gradient. The animation stops
/// when no loading descendant remains registered.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, this.linearGradient, this.child});

  /// Finds the nearest shimmer owner without creating a dependency.
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  /// Gradient to translate. When absent, [createShimmerGradient] is used.
  final LinearGradient? linearGradient;

  /// Loading subtree whose descendants may register with this shimmer.
  final Widget? child;

  @override
  ShimmerState createState() => ShimmerState();
}

/// State and geometry registry for a [Shimmer] owner.
///
/// Registered descendants contribute their bounds so separate placeholders
/// share one coordinate space. The state also owns the animation controller
/// and disposes it with the widget.
class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  int _listenerCount = 0;
  final Map<Object, Rect> _childBounds = {};

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _addListener() {
    _listenerCount++;
    if (_listenerCount == 1) {
      _shimmerController.repeat(min: -0.5, max: 1.5, period: 1000.ms);
    }
  }

  void _removeListener() {
    _listenerCount--;
    if (_listenerCount == 0) {
      _shimmerController.stop();
    }
  }

  /// Current gradient, translated to the shared animation position.
  LinearGradient get gradient {
    final baseGradient =
        widget.linearGradient ?? createShimmerGradient(context);
    return LinearGradient(
      colors: baseGradient.colors,
      stops: baseGradient.stops,
      begin: baseGradient.begin,
      end: baseGradient.end,
      transform: _SlidingGradientTransform(
        slidePercent: _shimmerController.value,
      ),
    );
  }

  void _registerChild(Object key, Rect bounds) {
    _childBounds[key] = bounds;
  }

  void _unregisterChild(Object key) {
    _childBounds.remove(key);
  }

  Rect? get _computedBounds {
    if (_childBounds.isEmpty) return null;

    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;

    for (final rect in _childBounds.values) {
      left = rect.left < left ? rect.left : left;
      top = rect.top < top ? rect.top : top;
      right = rect.right > right ? rect.right : right;
      bottom = rect.bottom > bottom ? rect.bottom : bottom;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Bounds covering all registered descendants, or the owner size.
  Size get effectiveSize {
    final computedBounds = _computedBounds;
    if (computedBounds != null) {
      return computedBounds.size;
    }
    return size;
  }

  /// Top left of the shared descendant bounds, or zero without registrations.
  Offset get effectiveOffset {
    final computedBounds = _computedBounds;
    if (computedBounds != null) {
      return computedBounds.topLeft;
    }
    return Offset.zero;
  }

  /// Whether the owner render object has completed layout.
  bool get isSized =>
      (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  /// The laid out size of the owner render object.
  Size get size => (context.findRenderObject()! as RenderBox).size;

  /// Converts [descendant]'s local [offset] into shimmer coordinates.
  Offset getDescendantOffset({
    required RenderBox? descendant,
    Offset offset = Offset.zero,
  }) {
    if (descendant == null) return offset;
    final shimmerBox = context.findRenderObject() as RenderBox?;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  /// Notifies consumers whenever the shared shimmer position changes.
  Listenable get shimmerChanges => _shimmerController;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

/// Applies the nearest [Shimmer] gradient to [child].
///
/// The child should contain shapes with solid colors that will be
/// replaced by the shimmer gradient.
class ShimmerLoading extends HookWidget {
  const ShimmerLoading({required this.child, super.key});

  /// Placeholder subtree whose solid colors receive the animated gradient.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shimmerChanges = useState<Listenable?>(null);
    final childKey = useMemoized(Object.new, []);

    useEffect(() {
      final shimmer = Shimmer.of(context);
      if (shimmer != null) {
        shimmer._addListener();
        shimmerChanges.value = shimmer.shimmerChanges;
        return shimmer._removeListener;
      }
      return null;
    }, []);

    useEffect(() {
      final shimmer = Shimmer.of(context);
      if (shimmer != null) {
        return () => shimmer._unregisterChild(childKey);
      }
      return null;
    }, [childKey]);

    useListenable(shimmerChanges.value);

    final shimmer = Shimmer.of(context);
    if (shimmer == null || !shimmer.isSized) {
      return const SizedBox();
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final offsetWithinShimmer = shimmer.getDescendantOffset(
      descendant: renderBox,
    );

    if (renderBox != null && renderBox.hasSize) {
      final childBounds = Rect.fromLTWH(
        offsetWithinShimmer.dx,
        offsetWithinShimmer.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
      shimmer._registerChild(childKey, childBounds);
    }

    final effectiveSize = shimmer.effectiveSize;
    final effectiveOffset = shimmer.effectiveOffset;
    final gradient = shimmer.gradient;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx + effectiveOffset.dx,
            -offsetWithinShimmer.dy + effectiveOffset.dy,
            effectiveSize.width,
            effectiveSize.height,
          ),
        );
      },
      child: child,
    );
  }
}

/// A convenient shimmer placeholder for a simple shaped loading region.
///
/// Use this as a quick placeholder for content that is loading.
class ShimmerBox extends HookWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.shape,
    this.color,
  });

  /// Creates a rectangular shimmer box with optional border radius.
  ShimmerBox.rectangle({
    super.key,
    this.width,
    this.height,
    BorderRadius? borderRadius,
    this.color,
  }) : shape = RoundedRectangleBorder(
         borderRadius: borderRadius ?? BorderRadius.circular(8),
       );

  /// Creates a circular shimmer box.
  const ShimmerBox.circle({super.key, this.width, this.height, this.color})
    : shape = const CircleBorder();

  /// Creates a stadium shaped shimmer box.
  const ShimmerBox.stadium({super.key, this.width, this.height, this.color})
    : shape = const StadiumBorder();

  final double? width;
  final double? height;
  final ShapeBorder? shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseColor = color ?? theme.colorScheme.surfaceContainerLowest;

    return ShimmerLoading(
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: baseColor,
          shape: shape ?? const RoundedRectangleBorder(),
          child: Surface(color: baseColor, child: const SizedBox()),
        ),
      ),
    );
  }
}
