import "package:typewriter_panel/typewriter_panel.dart";

/// Presents a compact empty state for inline list and table content.
///
/// [EmptyState] owns no loading or recovery state. The caller decides whether
/// the absence is normal, transient, or an error and supplies any recovery
/// action through [buttonText] and [onPressed]. Use [EmptyScreen] when the
/// surrounding page needs the full screen empty state treatment.
class EmptyState extends HookConsumerWidget {
  const EmptyState({
    required this.title,
    required this.description,
    this.icon,
    this.buttonText,
    this.onPressed,
    super.key,
  });

  /// Main title shown in a larger font.
  final String title;

  /// Short description placed below the title.
  final String description;

  /// Optional icon name understood by [Icones]. If null, no icon is displayed.
  final String? icon;

  /// Optional button label. When provided the button is shown.
  final String? buttonText;

  /// Callback for the button press. Ignored when `buttonText` is null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.all(context.spacing.space4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.only(bottom: context.spacing.space3),
                child: Icones(
                  icon,
                  size: 48,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: textColor),
            ),
            SizedBox(height: context.spacing.space2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            if (buttonText != null) ...[
              SizedBox(height: context.spacing.space4),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icones(Fa6Solid.plus),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
