import "package:typewriter_panel/typewriter_panel.dart";

/// How much room a resource item has where it is laid out.
enum ResourceItemDensity {
  /// A list or tree row.
  row,

  /// A graph node.
  node,

  /// A grid card.
  card,
}

/// Host chrome for a resource whose type declares no item presentation: its
/// icon and label in its accent. Selection, hover, focus and the routed state
/// come from the nearest [PresentationInteractionScope].
class ResourceItemChrome extends StatelessWidget {
  const ResourceItemChrome({
    required this.appearance,
    this.density = ResourceItemDensity.row,
    super.key,
  });

  final ResourceAppearance appearance;
  final ResourceItemDensity density;

  @override
  Widget build(BuildContext context) {
    final interaction = PresentationInteractionScope.of(context);
    final accent = appearance.accent;
    final emphasized =
        interaction.selected || interaction.routed || interaction.dropAccepted;
    final background = emphasized
        ? accent.withValues(alpha: 0.18)
        : interaction.hovered || interaction.focused
        ? accent.withValues(alpha: 0.08)
        : accent.withValues(alpha: 0);
    final label = Text(
      appearance.label,
      overflow: TextOverflow.ellipsis,
      maxLines: density == ResourceItemDensity.card ? 2 : 1,
      textAlign: density == ResourceItemDensity.card
          ? TextAlign.center
          : TextAlign.start,
      style: context.theme.textTheme.bodyMedium?.copyWith(
        fontWeight: interaction.routed ? FontWeight.w600 : null,
      ),
    );
    final content = switch (density) {
      ResourceItemDensity.card => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: context.spacing.space2,
        children: [
          ResourceIcon(icon: appearance.icon, color: accent, size: 40),
          label,
        ],
      ),
      _ => Row(
        spacing: context.spacing.space2,
        children: [
          ResourceIcon(icon: appearance.icon, color: accent, size: 18),
          Expanded(child: label),
        ],
      ),
    };
    final border = switch (density) {
      _ when interaction.dropRejected => Border.all(
        color: context.theme.colorScheme.error,
        width: 2,
      ),
      _ when interaction.dropAccepted => Border.all(color: accent, width: 2),
      ResourceItemDensity.row => null,
      _ => Border.all(
        color: emphasized ? accent : context.colors.borderSubtle,
        width: emphasized ? 2 : 1,
      ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space3,
        vertical: density == ResourceItemDensity.row
            ? context.spacing.space1
            : context.spacing.space2,
      ),
      decoration: BoxDecoration(
        color: density == ResourceItemDensity.row
            ? background
            : Color.alphaBlend(
                background,
                context.theme.colorScheme.surfaceContainerHighest,
              ),
        borderRadius: context.shapes.mediumBorderRadius,
        border: border,
      ),
      child: content,
    );
  }
}
