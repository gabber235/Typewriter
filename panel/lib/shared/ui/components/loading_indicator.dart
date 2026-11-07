import "package:typewriter_panel/typewriter_panel.dart";

/// Communicates that a region is waiting for asynchronous work to finish.
///
/// The [message] gives the pending operation a human readable status. By
/// default the indicator centers itself in the available parent; set [shrink]
/// when the parent already owns positioning and only an intrinsic sized child
/// is wanted.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    required this.message,
    this.shrink = false,
    super.key,
  });

  final String message;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    Widget widget = Enter(
      token: MotionToken.loadIn,
      child: MotionLabel(
        message,
        rippling: true,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );

    if (!shrink) {
      widget = Center(child: widget);
    }

    return widget;
  }
}
