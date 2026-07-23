import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class BlueprintSearchPreview extends StatelessWidget {
  const BlueprintSearchPreview({required this.context, super.key});

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
          blueprint: switch (result.payload) {
            final ElementBlueprint bp => bp,
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
    this.blueprint,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final ElementBlueprint? blueprint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surfaceColor = Surface.colorOf(context);

    final effectiveColor = blueprint?.color ?? context.colors.contentDisabled;
    final backgroundColor = Color.alphaBlend(
      effectiveColor.withValues(alpha: 0.22),
      surfaceColor,
    );
    final borderColor = effectiveColor.withValues(alpha: 0.45);
    final onColor = effectiveColor.onBrightness(Brightness.dark);

    final tags = blueprint?.tags ?? const <String>[];
    final tagBackground = Color.alphaBlend(
      effectiveColor.withValues(alpha: 0.3),
      surfaceColor,
    );

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
                    icon: blueprint?.icon ?? "fa-solid:cube",
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: context.spacing.space1,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colors.onSurface,
                                      fontSize: 14,
                                      height: 1.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  if (tags.isNotEmpty)
                                    for (final tag in tags)
                                      _SoftChip(
                                        label: tag.formatted,
                                        backgroundColor: tagBackground,
                                        foregroundColor: effectiveColor,
                                      ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            _TypeLabel(label: "BLUEPRINT"),
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
  final String icon;

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
      child: Icones(icon, color: onColor),
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

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: 10, color: foregroundColor),
      ),
    );
  }
}

class _PreviewData extends StatelessWidget {
  const _PreviewData({required this.data, this.subtitle});

  final Object data;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final map = _asMap(data);
    if (map == null) {
      return _StatusMessage(message: data.toString());
    }

    final description = map["description"];
    final fields = _normalizeFields(map["fields"]);

    final shouldShowDescription =
        description is String &&
        description.isNotEmpty &&
        (subtitle == null || subtitle!.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShowDescription) ...[
          _StatusMessage(message: description),
          if (fields.isNotEmpty) const SizedBox(height: 10),
        ],
        if (fields.isNotEmpty) _FieldsTable(fields: fields),
      ],
    );
  }

  Map<String, String> _normalizeFields(Object? fields) {
    if (fields is! Map) {
      return const {};
    }

    return fields.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  Map<String, dynamic>? _asMap(Object value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    try {
      final dynamic dynamicValue = value;
      final fields = dynamicValue.fields;
      return {
        "title": dynamicValue.title,
        "description": dynamicValue.description,
        "fields": fields,
      };
    } on Object {
      return null;
    }
  }
}

class _FieldsTable extends StatelessWidget {
  const _FieldsTable({required this.fields});

  final Map<String, String> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final entries = fields.entries.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.25),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(
                    entries[i].key,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(width: context.spacing.space2),
                Expanded(
                  child: Text(
                    entries[i].value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: context.shapes.mediumBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
