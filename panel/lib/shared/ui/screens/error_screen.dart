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

  /// Heading shown when the caller gives no title, so one failure always
  /// reads the same.
  static const defaultTitle = "Typewriter hit an error";

  /// Error heading. An empty value shows [defaultTitle].
  final String title;

  /// Diagnostic or user facing detail shown below the heading.
  final String message;

  /// Optional recovery content rendered after the error detail.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return EnterRun(
      child: Center(
        child: Column(
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
                  Enter(
                    token: MotionToken.loadIn,
                    child: Text(
                      title.isEmpty ? ErrorScreen.defaultTitle : title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: context.responsive(
                          mobile: 24,
                          tablet: 32,
                          desktop: 40,
                        ),
                        fontWeight: FontWeight.bold,
                        color: context.colors.dangerText,
                      ),
                    ),
                  ),
                  Enter(
                    token: MotionToken.loadIn,
                    child: Text(
                      "Something went wrong, please report this to the Typewriter discord.",
                      textAlign: TextAlign.center,
                      style: context.text.sentence.copyWith(
                        fontSize: context.responsive(
                          mobile: 14,
                          tablet: 16,
                          desktop: 20,
                        ),
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (message.isNotEmpty)
                    Enter(
                      token: MotionToken.loadIn,
                      child: SelectableText(
                        message,
                        textAlign: TextAlign.center,
                        style: context.text.sentence.copyWith(
                          fontSize: context.responsive(
                            mobile: 12,
                            tablet: 14,
                            desktop: 18,
                          ),
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.space6),
            if (child != null) Enter(token: MotionToken.loadIn, child: child!),
            Spacer(),
          ],
        ),
      ),
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
    return EnterRun(
      child: withIcon
          ? LayoutBuilder(
              builder: (context, constraints) {
                return _buildContent(context, constraints.hasBoundedHeight);
              },
            )
          : _buildContent(context, false),
    );
  }

  /// The illustration is a square as wide as the space allows. When the
  /// height is [bounded] it shrinks to the height the text leaves free, so
  /// the title and message always fit.
  Widget _buildContent(BuildContext context, bool bounded) {
    const illustration = MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      child: AspectRatio(
        aspectRatio: 1,
        child: RiveAsset(
          asset: "assets/robot_island.riv",
          stateMachineName: "Motion",
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: context.spacing.space2,
      children: [
        if (withIcon && bounded)
          const Flexible(child: illustration)
        else if (withIcon)
          illustration,
        Enter(
          token: MotionToken.loadIn,
          child: Text(
            title.isEmpty ? ErrorScreen.defaultTitle : title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: context.responsive(mobile: 14, tablet: 16, desktop: 18),
              fontWeight: FontWeight.bold,
              color: context.colors.dangerText,
            ),
          ),
        ),
        Enter(
          token: MotionToken.loadIn,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.sentence.copyWith(
              fontSize: context.responsive(mobile: 10, tablet: 12, desktop: 14),
              color: context.colors.contentSecondary,
            ),
          ),
        ),
        if (child != null) Enter(token: MotionToken.loadIn, child: child!),
      ],
    );
  }
}
