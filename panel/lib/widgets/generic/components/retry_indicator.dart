import "package:flutter/material.dart";

class RetryIndicator extends StatelessWidget {
  const RetryIndicator({
    this.message = "Retrying...",
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(),
        ),
        SizedBox(width: 12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
