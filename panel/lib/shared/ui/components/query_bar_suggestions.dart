part of "query_bar.dart";

Widget _buildSuggestionPanel({
  required BuildContext context,
  required List<QuerySuggestion> suggestions,
  required int? activeSuggestionIndex,
  required ValueChanged<QuerySuggestion> onTapSuggestion,
  required ValueChanged<int> onHoverIndex,
}) {
  final theme = Theme.of(context);
  final menuStyle = theme.dropdownMenuTheme.menuStyle ?? const MenuStyle();
  final states = <WidgetState>{};
  final shape =
      menuStyle.shape?.resolve(states) ??
      RoundedRectangleBorder(borderRadius: context.shapes.mediumBorderRadius);
  final padding =
      menuStyle.padding?.resolve(states) ??
      const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
  final elevation = menuStyle.elevation?.resolve(states) ?? 1;
  final backgroundColor =
      menuStyle.backgroundColor?.resolve(states) ?? theme.colorScheme.surface;

  return Material(
    key: ValueKey(suggestions.key),
    elevation: elevation,
    color: backgroundColor,
    shape: shape,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: padding,
      child: Container(
        key: const ValueKey("query_bar_suggestions"),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final isActive = activeSuggestionIndex == index;

            return MouseRegion(
              key: ValueKey("query_bar_suggestion_$index"),
              onEnter: (_) => onHoverIndex(index),
              child: MenuItemButton(
                style: _suggestionItemStyle(context, isActive: isActive),
                trailingIcon: Text(
                  _suggestionTypeLabel(suggestion),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                requestFocusOnHover: false,
                onPressed: () => onTapSuggestion(suggestion),
                child: Text(suggestion.label, overflow: TextOverflow.ellipsis),
              ),
            );
          },
        ),
      ),
    ),
  );
}

ButtonStyle? _suggestionItemStyle(
  BuildContext context, {
  required bool isActive,
}) {
  if (!isActive) {
    return null;
  }

  final themeStyle = MenuButtonTheme.of(context).style;
  final defaultStyle = const MenuItemButton().defaultStyleOf(context);

  Color? resolveFocusedColor(WidgetStateProperty<Color?>? property) {
    return property?.resolve(<WidgetState>{WidgetState.focused});
  }

  final focusedForegroundColor = resolveFocusedColor(
    themeStyle?.foregroundColor ?? defaultStyle.foregroundColor,
  );
  final focusedIconColor = resolveFocusedColor(
    themeStyle?.iconColor ?? defaultStyle.iconColor,
  );
  final focusedOverlayColor = resolveFocusedColor(
    themeStyle?.overlayColor ?? defaultStyle.overlayColor,
  );
  final focusedBackgroundColor =
      resolveFocusedColor(themeStyle?.backgroundColor) ??
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

  return (themeStyle ?? const ButtonStyle()).copyWith(
    backgroundColor: WidgetStatePropertyAll<Color>(focusedBackgroundColor),
    foregroundColor: focusedForegroundColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedForegroundColor),
    iconColor: focusedIconColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedIconColor),
    overlayColor: focusedOverlayColor == null
        ? null
        : WidgetStatePropertyAll<Color>(focusedOverlayColor),
  );
}

String _suggestionTypeLabel(QuerySuggestion suggestion) {
  return switch (suggestion) {
    SelectorKeySuggestion() => "Selector",
    SelectorValueSuggestion() => "Value",
    OperatorSuggestion() => "Operator",
  };
}

bool _isSelectorOrOperatorSuggestion(QuerySuggestion suggestion) {
  return switch (suggestion) {
    SelectorKeySuggestion() => true,
    OperatorSuggestion() => true,
    _ => false,
  };
}

bool _shouldShowHelperRow(List<QuerySuggestion> suggestions) {
  if (suggestions.isEmpty) {
    return false;
  }

  return suggestions.every(_isSelectorOrOperatorSuggestion);
}

_HelperBadgeData _helperBadgeData(
  List<QuerySuggestion> suggestions, {
  int maxItems = 8,
}) {
  assert(maxItems > 0, "maxItems must be greater than zero");

  final uniqueLabels = <String>[];
  final seenLabels = <String>{};

  for (final suggestion in suggestions) {
    if (!_isSelectorOrOperatorSuggestion(suggestion)) {
      continue;
    }

    if (seenLabels.add(suggestion.label)) {
      uniqueLabels.add(suggestion.label);
    }
  }

  if (uniqueLabels.length <= maxItems) {
    return _HelperBadgeData(labels: uniqueLabels, hiddenCount: 0);
  }

  return _HelperBadgeData(
    labels: uniqueLabels.take(maxItems).toList(growable: false),
    hiddenCount: uniqueLabels.length - maxItems,
  );
}

Widget _buildHelperBadge(BuildContext context, String label, {Key? key}) {
  final colors = Theme.of(context).colorScheme;

  return Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: context.shapes.smallBorderRadius,
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
    ),
  );
}

class _HelperBadgeData {
  const _HelperBadgeData({required this.labels, required this.hiddenCount});

  final List<String> labels;
  final int hiddenCount;
}
