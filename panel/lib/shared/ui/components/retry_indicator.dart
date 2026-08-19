import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
