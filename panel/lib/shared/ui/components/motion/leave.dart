import "package:typewriter_panel/typewriter_panel.dart";

/// Squashes [child] shut as [progress] goes from 1 to 0: height, vertical
/// scale and opacity go to zero together, so its neighbours close the gap
/// with it. Play `listOut` on the progress.
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
        if (open == 1) return child!;
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: open,
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
