import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/main.dart";

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    required this.title,
    required this.message,
    this.child,
    super.key,
  });

  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Expanded(
            flex: 6,
            child: MouseRegion(
              cursor: SystemMouseCursors.zoomIn,
              child: RiveAnimation.asset(
                "assets/robot_island.riv",
                stateMachines: ["Motion"],
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 8,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:
                        context.responsive(mobile: 24, tablet: 32, desktop: 40),
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.responsive(
                      mobile: 14,
                      tablet: 16,
                      desktop: 20,
                    ),
                    color: Colors.grey,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
          SizedBox(height: 24),
          if (child != null)
            child!
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms)
                .slideY(begin: 0.1, end: 0),
          Spacer(),
        ],
      ),
    );
  }
}
