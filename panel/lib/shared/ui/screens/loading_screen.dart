import "package:typewriter_panel/typewriter_panel.dart";

/// Fills a route or application shell while its initial work is pending.
///
/// The screen communicates progress without owning the operation. Replace it
/// with the resulting route or an [ErrorScreen] when that work completes.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({this.title = "Waiting for connection", super.key});

  /// Heading that identifies the pending operation.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Expanded(
          flex: 8,
          child: const RiveAsset(
            asset: "assets/tour.riv",
            stateMachineName: "state_machine",
          ),
        ),
        SizedBox(height: context.spacing.space6),
        Text(
          title,
          style: Theme.of(context).textTheme.displayLarge!
              .copyWith(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        ConnectionScroller(
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 20, color: context.colors.contentSecondary),
        ),
        SizedBox(height: context.spacing.space6),
        Spacer(),
      ],
    );
  }
}

/// The one status line beneath a [LoadingScreen] heading: it ripples while
/// the connection is pending.
class ConnectionScroller extends StatelessWidget {
  const ConnectionScroller({this.style, super.key});

  /// Text style of the status line.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return MotionLabel("Connecting to the realm", rippling: true, style: style);
  }
}
