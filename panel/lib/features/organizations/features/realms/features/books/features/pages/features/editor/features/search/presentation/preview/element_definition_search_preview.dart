import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "element_definition_search_preview_content.dart";

class ElementDefinitionSearchPreview extends StatelessWidget {
  const ElementDefinitionSearchPreview({required this.context, super.key});

  final SearchResultPreviewContext context;

  @override
  Widget build(BuildContext context) {
    return switch (this.context) {
      SearchResultPreviewContextLoading(:final result) => _PreviewFrame(
        title: result.title ?? result.id,
        subtitle: result.subtitle,
        child: const Center(child: CircularProgressIndicator()),
      ),
      SearchResultPreviewContextData(:final result, :final data) =>
        _PreviewFrame(
          title: result.title ?? result.id,
          subtitle: result.subtitle,
          elementDefinition: switch (result.payload) {
            final ElementDefinition definition => definition,
            _ => null,
          },
          child: _PreviewData(data: data, subtitle: result.subtitle),
        ),
      SearchResultPreviewContextError(:final result, :final message) =>
        _PreviewFrame(
          title: result.title ?? result.id,
          subtitle: result.subtitle,
          child: _StatusMessage(
            message: message,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
    };
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.elementDefinition,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final ElementDefinition? elementDefinition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaceColor = Surface.colorOf(context);

    final effectiveColor =
        elementDefinition?.color ?? context.colors.contentDisabled;
    final backgroundColor = Color.alphaBlend(
      effectiveColor.withValues(alpha: 0.22),
      surfaceColor,
    );
    final borderColor = effectiveColor.withValues(alpha: 0.45);
    final onColor = effectiveColor.onBrightness(Brightness.dark);

    return Padding(
      padding: EdgeInsets.all(context.spacing.space2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: context.shapes.mediumBorderRadius,
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _IconTile(
                    color: effectiveColor,
                    onColor: onColor,
                    icon:
                        elementDefinition?.icon ??
                        const IconValue.iconify("fa-solid:cube"),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.onSurface,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _TypeLabel(label: "ELEMENT"),
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.color,
    required this.onColor,
    required this.icon,
  });

  final Color color;
  final Color onColor;
  final IconValue icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: context.shapes.smallBorderRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.spacing.space2),
      child: Icones.value(icon, color: onColor),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
