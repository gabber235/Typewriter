import "package:typewriter_panel/typewriter_panel.dart";

/// Presents a full size recoverable error state for a route or application shell.
///
/// [message] is selectable so users can copy diagnostic context. [child] is
/// reserved for a recovery action or other caller owned follow up control.
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

  /// Error heading. An empty value selects a title from [funnyErrorTitles].
  final String title;

  /// Diagnostic or user facing detail shown below the heading.
  final String message;

  /// Optional recovery content rendered after the error detail.
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
        SizedBox(height: context.spacing.space6),
        Padding(
          padding: EdgeInsets.all(context.spacing.space2),
          child: Column(
            spacing: context.spacing.space2,
            children: [
              Text(
                    title.isEmpty ? funnyErrorTitles.randomElement() : title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                SelectableText(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
        SizedBox(height: context.spacing.space6),
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

/// Compact error state for inline content and constrained panels.
///
/// Unlike [ErrorScreen], this variant does not claim the available page height.
class SmallErrorScreen extends ErrorScreen {
  const SmallErrorScreen({
    required super.title,
    required super.message,
    this.withIcon = false,
    super.child,
    super.key,
  });

  /// Whether to include the animated error illustration.
  final bool withIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: context.responsive(
                  mobile: 14,
                  tablet: 16,
                  desktop: 18,
                ),
                fontWeight: FontWeight.bold,
                color: context.colors.danger,
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),
        Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: context.responsive(
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                color: context.colors.contentSecondary,
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
