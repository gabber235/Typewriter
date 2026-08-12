part of "element_definition_search_preview.dart";

class _PreviewData extends StatelessWidget {
  const _PreviewData({required this.data, this.subtitle});

  final Object data;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final map = data._previewMap;
    if (map == null) return _StatusMessage(message: data.toString());
    final description = map["description"];
    final Object? rawFields = map["fields"];
    final fields = rawFields._normalizedFields;
    final showDescription =
        description is String &&
        description.isNotEmpty &&
        (subtitle == null || subtitle!.isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDescription) ...[
          _StatusMessage(message: description),
          if (fields.isNotEmpty) const SizedBox(height: 10),
        ],
        if (fields.isNotEmpty) _FieldsTable(fields: fields),
      ],
    );
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
          ).textTheme.bodyMedium?.copyWith(color: color ?? colors.onSurface),
        ),
      ),
    );
  }
}

extension on Object? {
  Map<String, String> get _normalizedFields {
    final value = this;
    if (value is! Map) return const {};
    return value.map(
      (key, fieldValue) => MapEntry(key.toString(), fieldValue.toString()),
    );
  }
}

extension on Object {
  Map<String, dynamic>? get _previewMap {
    if (this case final Map<String, dynamic> value) return value;
    if (this case final Map value) {
      return value.map(
        (key, fieldValue) => MapEntry(key.toString(), fieldValue),
      );
    }
    try {
      final dynamic value = this;
      return {
        "title": value.title,
        "description": value.description,
        "fields": value.fields,
      };
    } on Object {
      return null;
    }
  }
}
