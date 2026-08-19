import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
    Widget widget =
        Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: context.spacing.space6),
                Text(message, style: Theme.of(context).textTheme.titleLarge),
              ],
            )
            .animate()
            .slideY(
              duration: 1.seconds,
              begin: 0.05,
              end: 0,
              curve: Curves.easeInOutCubic,
            )
            .fadeIn();

    if (!shrink) {
      widget = Center(child: widget);
    }

    return widget;
  }
}
