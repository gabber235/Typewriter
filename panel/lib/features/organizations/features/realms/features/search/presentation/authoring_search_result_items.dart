import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Keeps search selection, activation, and keyboard behavior in Flutter while
/// the Realm supplied authoring role owns the visual body.
class AuthoringSearchResultItem extends StatelessWidget {
  const AuthoringSearchResultItem({
    required this.payload,
    required this.selected,
    required this.focused,
    required this.loading,
    required this.onTap,
    required this.shortcutActivator,
    super.key,
  });

  final AuthoringSearchResultPayload payload;
  final bool selected;
  final bool focused;
  final bool loading;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SearchResultCard(
      color: color,
      prefix: loading
          ? SearchResultIconTile(
              color: color,
              onColor: color.on(context),
              icon: const SizedBox.shrink(),
              focused: focused,
              loading: true,
            )
          : null,
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: IgnorePointer(
        child: ComposedEditor(
          model: payload.presentation.model,
          readOnly: true,
          historyNamespace: "authoring.search.${payload.definition.value}",
        ),
      ),
      suffix: SearchResultSuffix(
        label: payload.definition.value,
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
