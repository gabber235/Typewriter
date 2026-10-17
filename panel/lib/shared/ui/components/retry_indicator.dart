import "package:typewriter_panel/typewriter_panel.dart";

/// Reports that an operation is being retried.
///
/// [message] should describe the operation rather than imply that the retry
/// already succeeded. The widget is intentionally non interactive; retry
/// ownership and cancellation remain with the caller.
class RetryIndicator extends StatelessWidget {
  const RetryIndicator({this.message = "Retrying...", super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
        SizedBox(width: context.spacing.space3),
        Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
