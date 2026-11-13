import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's bottom sheet: it rises from the bottom edge with surfaceIn
/// and sinks back with panelOut, over the dialog veil.
///
/// The sheet rests on the bottom edge, centred and no wider than
/// [maxWidth], and its content may take the whole height. Escape, a click
/// on the veil, or a drag down past half the sheet's height closes it; a
/// shorter drag settles back. Words inside read in the panel's body style.
class PanelSheetRoute<T> extends PopupRoute<T> {
  PanelSheetRoute({
    required this.arrive,
    required this.leave,
    required this.builder,
    required this.themes,
    required this.barrierColor,
    super.settings,
  });

  /// The widest a sheet grows, a reading column.
  static const double maxWidth = 640;

  final MotionTimeline arrive;
  final MotionTimeline leave;
  final WidgetBuilder builder;
  final CapturedThemes themes;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => "Close sheet";

  @override
  Duration get transitionDuration => arrive.duration;

  @override
  Duration get reverseTransitionDuration => leave.duration;

  late final Animation<double> _travel = CurvedAnimation(
    parent: animation!,
    curve: arrive.curve,
    reverseCurve: leave.curve.flipped,
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: _SheetBody(
          route: this,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AnimatedBuilder(
    animation: _travel,
    child: child,
    // The spring may overshoot; the sheet never lifts off the bottom edge.
    builder: (context, child) => FractionalTranslation(
      translation: Offset(0, 1 - _travel.value.clamp(0.0, 1.0)),
      child: child,
    ),
  );

  /// Follows a finger dragging the sheet down by [delta] of its [height].
  void _drag(double delta, double height) {
    final controller = this.controller;
    if (controller == null || height <= 0) return;
    controller.value -= delta / height;
  }

  /// Closes the sheet when it was dragged past half or flung down, and
  /// otherwise lets it settle back.
  void _release(double velocity, double height) {
    final controller = this.controller;
    if (controller == null) return;
    final flung = height > 0 && velocity / height > 2;
    if (flung || controller.value < 0.5) {
      navigator?.pop();
    } else {
      controller.forward();
    }
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.route, required this.child});

  final PanelSheetRoute<Object?> route;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double height() => context.size?.height ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) =>
          route._drag(details.primaryDelta ?? 0, height()),
      onVerticalDragEnd: (details) =>
          route._release(details.primaryVelocity ?? 0, height()),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!
            .copyWith(color: context.colors.contentPrimary),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// A rounded card that floats inside a sheet, clear of the screen edges,
/// no taller than [maxHeight].
class SheetCard extends StatelessWidget {
  const SheetCard({required this.maxHeight, required this.child, super.key});

  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.surfaceContainer;
    return SafeArea(
      minimum: EdgeInsets.all(context.spacing.space3),
      child: ClipRRect(
        borderRadius: context.shapes.largeBorderRadius,
        child: ColoredBox(
          color: color,
          child: Surface(
            color: color,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
