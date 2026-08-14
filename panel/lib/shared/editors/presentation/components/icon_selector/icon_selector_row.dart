part of "icon_selector.dart";

Widget _buildIconSearchResultRow(SearchResultRowContext context) {
  final payload = context.result.payload;
  if (payload is! IconSearchResultPayload) {
    return MissingSearchResultRendererRow(result: context.result);
  }
  return _IconSearchResultRow(context: context, payload: payload);
}

class _IconSearchResultRow extends ConsumerWidget {
  const _IconSearchResultRow({required this.context, required this.payload});

  final SearchResultRowContext context;
  final IconSearchResultPayload payload;

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    final colors = Theme.of(buildContext).colorScheme;
    final background = context.focused
        ? colors.secondaryContainer
        : colors.surface.withValues(alpha: 0);
    final foreground = context.focused
        ? colors.onSecondaryContainer
        : colors.onSurface;
    return Semantics(
      button: true,
      selected: context.selected,
      focused: context.focused,
      label:
          "${payload.name.replaceAll("-", " ").titleCase()}, "
          "${payload.collection}, ${payload.identifier}",
      child: Tooltip(
        message: payload.identifier,
        child: Material(
          color: background,
          child: InkWell(
            onTap: context.loading ? null : context.onTap,
            child: SizedBox(
              height: _iconResultExtent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 32,
                      child: Center(
                        child: ref.read(iconSelectorIconBuilderProvider)(
                          buildContext,
                          IconValue.iconify(payload.identifier),
                          22,
                          foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payload.name.replaceAll("-", " ").titleCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              buildContext,
                            ).textTheme.bodyMedium?.copyWith(color: foreground),
                          ),
                          Text(
                            payload.collection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(buildContext).textTheme.labelSmall
                                ?.copyWith(
                                  color: foreground.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (context.loading)
                      const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
