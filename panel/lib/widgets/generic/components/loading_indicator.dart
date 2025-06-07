import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      )
          .animate()
          .slideY(
            duration: 1.seconds,
            begin: 0.05,
            end: 0,
            curve: Curves.easeInOutCubic,
          )
          .fadeIn(),
    );
  }
}
