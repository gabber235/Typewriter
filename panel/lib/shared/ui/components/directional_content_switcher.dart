import "package:typewriter_panel/typewriter_panel.dart";

/// Switches keyed content with a slide direction derived from index changes.
///
/// A larger index enters from the right and a smaller index enters from the
/// left. The caller must provide a key that changes with
/// the content; the index only supplies transition direction.
class DirectionalContentSwitcher extends StatefulWidget {
  const DirectionalContentSwitcher({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<DirectionalContentSwitcher> createState() =>
      _DirectionalContentSwitcherState();
}

class _DirectionalContentSwitcherState
    extends State<DirectionalContentSwitcher> {
  int _direction = 0;

  @override
  void didUpdateWidget(DirectionalContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _direction = widget.index.compareTo(oldWidget.index);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.child.key != null);
    // Incoming content enters from its side with loadIn; outgoing content
    // leaves at once. The size grows with surfaceIn and shrinks with
    // panelOut.
    final enter = motionTimeline(context, MotionToken.loadIn);
    // Without motion the new content replaces the old at once.
    if (enter.isInstant) return widget.child;
    final currentKey = widget.child.key;
    final direction = _direction.toDouble();

    return MotionSize(
      shrink: MotionToken.panelOut,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: enter.duration,
          reverseDuration: Duration.zero,
          switchInCurve: enter.curve,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              for (final child in previousChildren)
                Positioned(top: 0, left: 0, right: 0, child: child),
              ?currentChild,
            ],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == currentKey;
            final offset = Offset(incoming ? direction : -direction, 0);
            final position = Tween(
              begin: offset,
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: position, child: child),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
