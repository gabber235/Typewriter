import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/rive.dart";

const funnyErrorTitles = [
  "The plot thickened too much",
  "This quest has no walkthrough",
  "A dialogue option is missing",
  "The NPC forgot their lines",
  "Cut! Technical difficulties",
  "A plot hole swallowed the code",
  "The typewriter jammed",
  "This scene needs a rewrite",
  "Narrative engine stalled",
  "The story arc snapped",
  "An unexpected boss encounter",
  "Cinematic render failed",
  "Character sheet corrupted",
  "The writer is on a coffee break",
  "A wild bug appeared",
  "This page is intentionally left broken",
  "The footnotes declared independence",
  "The server said no",
  "A creeper got into the codebase",
  "The manuscript caught fire",
  "The narrator is speechless",
  "A chapter went missing",
  "The editor rage quit",
  "Writer's block is real",
  "This is not in the script",
  "An unscripted event occurred",
  "The story broke the fourth wall",
  "A plot twist nobody asked for",
  "The protagonist is stuck in a loop",
  "To be continued, after this error",
  "The antagonist wins this round",
  "Spellcheck gave up",
  "This narrative branch is a dead end",
  "The story tree lost a branch",
  "Character voice mismatch",
  "The prologue became the epilogue",
  "The page numbers revolted",
  "The final draft was just a dream",
  "The appendix rebelled",
  "The midpoint crisis spilled into the code",
  "Unreliable narrator strikes again",
  "The timeline has a paradox",
  "A subplot ate the main thread",
  "The exposition dragged on too long",
  "The red pen ran out of judgment",
];

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    this.title = "",
    this.message = "",
    this.child,
    super.key,
  });

  const factory ErrorScreen.small({
    required String title,
    required String message,
    Widget? child,
    bool withIcon,
    Key? key,
  }) = SmallErrorScreen;

  final String title;
  final String message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Spacer(),
        Expanded(
          flex: 6,
          child: MouseRegion(
            cursor: SystemMouseCursors.zoomIn,
            child: const RiveAsset(
              asset: "assets/robot_island.riv",
              stateMachineName: "Motion",
            ),
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 8,
            children: [
              Text(
                    title.isEmpty ? funnyErrorTitles.randomElement() : title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(
                        mobile: 24,
                        tablet: 32,
                        desktop: 40,
                      ),
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
              Text(
                    "Something went wrong, please report this to the Typewriter discord.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(
                        mobile: 14,
                        tablet: 16,
                        desktop: 20,
                      ),
                      color: colors.onSurfaceVariant,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
              if (message.isNotEmpty)
                Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.responsive(
                          mobile: 12,
                          tablet: 14,
                          desktop: 18,
                        ),
                        color: colors.onSurface,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
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
    );
  }
}

class SmallErrorScreen extends ErrorScreen {
  const SmallErrorScreen({
    required super.title,
    required super.message,
    this.withIcon = false,
    super.child,
    super.key,
  });

  final bool withIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (withIcon)
          MouseRegion(
            cursor: SystemMouseCursors.zoomIn,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth == double.infinity
                    ? constraints.maxHeight
                    : constraints.maxWidth;
                return SizedBox(
                  width: size,
                  height: size,
                  child: const RiveAsset(
                    asset: "assets/robot_island.riv",
                    stateMachineName: "Motion",
                  ),
                );
              },
            ),
          ),
        Text(
              title.isEmpty ? funnyErrorTitles.randomElement() : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
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
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: Colors.grey,
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0),
        if (child != null)
          child!
              .animate()
              .fadeIn(duration: 300.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
