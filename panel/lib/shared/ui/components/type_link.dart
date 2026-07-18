import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:url_launcher/url_launcher.dart";

/// Small tappable text widget that displays a type/kind label with a hover
/// underline and (optionally) opens a documentation URL when clicked.
///
/// Color handling:
/// - Provide a required [lightColor].
/// - Optionally provide a [darkColor]; if omitted, [lightColor] is reused.
/// - The active display color is chosen based on current [ThemeData.brightness].
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

  final String text;
  final Color lightColor;
  final Color? darkColor;
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
              decoration:
                  highlight ? TextDecoration.underline : TextDecoration.none,
              decorationColor: baseColor,
            ) ??
            TextStyle(
              color: baseColor,
              decoration:
                  highlight ? TextDecoration.underline : TextDecoration.none,
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
      mouseCursor:
          clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
