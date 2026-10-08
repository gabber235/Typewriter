import "package:typewriter_panel/typewriter_panel.dart";

Widget buildAuthoringCreationSearchResultItem(SearchResultRowContext context) {
  return AuthoringCreationSearchResultItem(
    option: context.result.payload as AuthoringCreationOption,
    selected: context.selected,
    focused: context.focused,
    onTap: context.onTap,
    shortcutActivator: context.shortcutActivator,
  );
}

class AuthoringCreationSearchResultItem extends StatelessWidget {
  const AuthoringCreationSearchResultItem({
    required this.option,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final AuthoringCreationOption option;
  final bool selected;
  final bool focused;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = option.display;
    final color =
        display?.color.parsedDisplayColor ?? theme.colorScheme.primary;
    final icon = display?.icon.trim();
    final description = display?.description.trim();
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.on(context),
        icon: icon == null || icon.isEmpty
            ? const Icon(Icons.add)
            : Icones(icon),
        focused: focused,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: option.label),
          if (description != null && description.isNotEmpty)
            SearchResultDescription(description: description),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "resource",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

extension on String {
  Color? get parsedDisplayColor {
    if (trim().isEmpty) return null;
    try {
      return parseColorHex(this, includeAlpha: true);
    } on FormatException {
      return null;
    }
  }
}
