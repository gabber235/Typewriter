import "package:typewriter_panel/typewriter_panel.dart";

/// A [RawDialogRoute] whose arrival and leave are motion tokens. With
/// [sinksPage] the page behind it scales back while it is open.
class MotionDialogRoute<T> extends RawDialogRoute<T> {
  MotionDialogRoute({
    required this.arrive,
    required this.leave,
    required this.originScale,
    required WidgetBuilder builder,
    required CapturedThemes themes,
    this.origin = Alignment.center,
    this.sinksPage = false,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.settings,
    super.traversalEdgeBehavior,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             themes.wrap(Builder(builder: builder)),
         transitionDuration: arrive.duration,
       );

  final MotionTimeline arrive;
  final MotionTimeline leave;

  /// The scale the surface grows from.
  final double originScale;

  /// The point the surface grows out of.
  final Alignment origin;
  final bool sinksPage;
  PageBackdrop? _backdrop;

  // RawDialogRoute takes one duration; the leave has its own.
  @override
  Duration get reverseTransitionDuration => leave.duration;

  late final Animation<double> _travel = CurvedAnimation(
    parent: animation!,
    curve: arrive.curve,
    reverseCurve: leave.curve.flipped,
  );

  @override
  TickerFuture didPush() {
    if (sinksPage) {
      final backdrop = ProviderScope.containerOf(
        navigator!.context,
        listen: false,
      ).read(pageBackdropProvider);
      _backdrop = backdrop;
      backdrop.sink(_travel);
    }
    return super.didPush();
  }

  @override
  void dispose() {
    _backdrop?.release(_travel);
    super.dispose();
  }

  // Replaces RawDialogRoute's default fade.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AnimatedBuilder(
    animation: _travel,
    child: child,
    builder: (context, child) => Opacity(
      opacity: _travel.value.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: lerpDouble(originScale, 1, _travel.value),
        alignment: origin,
        child: child,
      ),
    ),
  );
}

/// The open sinking routes; the page behind scales with the newest one.
final pageBackdropProvider = Provider<PageBackdrop>((ref) {
  final backdrop = PageBackdrop();
  ref.onDispose(backdrop.dispose);
  return backdrop;
});

/// The travels of the open dialogs that sink the page, newest last.
final class PageBackdrop extends ChangeNotifier {
  final List<Animation<double>> _open = [];

  /// The travel the page follows, or null with no dialog open.
  Animation<double>? get top => _open.lastOrNull;

  void sink(Animation<double> travel) {
    _open.add(travel);
    notifyListeners();
  }

  void release(Animation<double> travel) {
    // A route the navigator disposes after its provider scope finds no
    // listeners left to tell.
    if (_open.remove(travel) && !_disposed) notifyListeners();
  }

  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Scales [child] back by dialogIn's behindScale while a dialog that sinks
/// the page is open, by the same travel as the dialog.
class DialogBackdrop extends HookConsumerWidget {
  const DialogBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backdrop = ref.watch(pageBackdropProvider);
    useListenable(backdrop);
    final travel = backdrop.top;
    if (travel == null) return child;
    final behind = context.motion
        .spec(MotionToken.dialogIn)
        .landing
        .behindScale;
    return AnimatedBuilder(
      animation: travel,
      child: child,
      builder: (context, child) => Transform.scale(
        scale: lerpDouble(1, behind, travel.value),
        child: child,
      ),
    );
  }
}
