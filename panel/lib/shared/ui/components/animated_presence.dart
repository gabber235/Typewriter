import "package:typewriter_panel/typewriter_panel.dart";

/// One block that is shown or not outside a sliver list, such as the bulk
/// action bar a selection brings: it arrives with rowIn and squashes shut
/// with listOut, so the content below closes the gap. A block present at
/// mount does not move; one shown again while it leaves turns back from
/// where it is.
class AnimatedPresence extends HookWidget {
  const AnimatedPresence({required this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final shown = useRef<Widget?>(child);
    if (child != null) shown.value = child;
    final present = child != null;
    final progress = useMotion(
      present ? MotionToken.rowIn : MotionToken.listOut,
      present ? 1 : 0,
    );
    // useMotion rebuilds on every tick, so settling at 0 is seen here.
    final gone = progress.settled && progress.value <= 0;
    final last = shown.value;
    if (last == null || (!present && gone)) return const SizedBox.shrink();
    return Leave(
      progress: present ? kAlwaysCompleteAnimation : progress,
      child: Enter(
        progress: present ? progress : kAlwaysCompleteAnimation,
        child: ExcludeInteraction(excluding: !present, child: last),
      ),
    );
  }
}
