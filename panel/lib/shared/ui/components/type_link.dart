import "package:typewriter_panel/typewriter_panel.dart";

/// Displays a type label that can open its documentation URL.
///
/// When [url] is absent the label remains noninteractive. When it is present,
/// pointer and keyboard focus feedback are exposed through semantics and the
/// URL is opened only after it passes the platform launch check. [darkColor]
/// replaces [lightColor] in dark themes when supplied.
class TypeLink extends HookWidget {
  const TypeLink({
    required this.text,
    required this.lightColor,
    this.darkColor,
    this.url,
    this.style,
    this.maxLines = 1,
    this.openInNewTab = true,
    super.key,
  });

  /// Label exposed both visually and to accessibility services.
  final String text;

  final Color lightColor;
  final Color? darkColor;

  /// Documentation target. Null disables interaction and focus handling.
  final String? url;
  final TextStyle? style;
  final int maxLines;

  final bool openInNewTab;

  @override
  Widget build(BuildContext context) {
    final hovering = useState(false);
    final focused = useState(false);
    final launching = useState(false);

    final baseColor =
        (context.isDarkMode ? (darkColor ?? lightColor) : lightColor)
            .withValues(alpha: 0.9);

    final clickable = url != null;
    final highlight = hovering.value || focused.value;

    final effectiveStyle =
        (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
          color: baseColor,
          decoration: highlight
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: baseColor,
        ) ??
        Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: baseColor,
          decoration: highlight
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: baseColor,
        );

    Future<void> handleTap() async {
      final target = url;
      if (target == null || launching.value) return;
      Uri? uri;
      try {
        uri = Uri.parse(target);
      } on FormatException {
        return;
      }

      if (!await canLaunchUrl(uri)) return;

      launching.value = true;
      try {
        await launchUrl(
          uri,
          mode: openInNewTab
              ? LaunchMode.platformDefault
              : LaunchMode.inAppBrowserView,
        );
      } finally {
        launching.value = false;
      }
    }

    return FocusableActionDetector(
      enabled: clickable,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (clickable) unawaited(handleTap());
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            if (clickable) unawaited(handleTap());
            return null;
          },
        ),
      },
      mouseCursor: clickable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (focus) => focused.value = focus,
      onShowHoverHighlight: (hover) => hovering.value = hover,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: clickable ? handleTap : null,
        child: Semantics(
          button: clickable,
          link: clickable,
          label: text,
          enabled: clickable,
          onTap: clickable ? () => unawaited(handleTap()) : null,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.fastEaseInToSlowEaseOut,
            style: effectiveStyle,
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
