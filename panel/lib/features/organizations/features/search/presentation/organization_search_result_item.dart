import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class OrganizationSearchResultItem extends StatelessWidget {
  const OrganizationSearchResultItem({
    required this.name,
    required this.logoUrl,
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  factory OrganizationSearchResultItem.organization({
    required OrganizationData organization,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return OrganizationSearchResultItem(
      name: organization.name.formatted,
      logoUrl: organization.logoUrl,
      selected: selected,
      focused: focused,
      loading: loading,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final String name;
  final String logoUrl;
  final bool selected;
  final bool focused;
  final bool loading;

  final VoidCallback? onTap;

  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.colorScheme.onSecondaryContainer;
    return SearchResultCard(
      color: color,
      prefix: OrganizationLogo(logoUrl: logoUrl),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: SearchResultTitle(title: name),
      suffix: SearchResultSuffix(
        label: "organization",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}

class CreateOrganizationSearchResultItem extends StatelessWidget {
  const CreateOrganizationSearchResultItem({
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  final bool selected;
  final bool focused;
  final bool loading;

  final VoidCallback? onTap;

  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color = context.theme.colorScheme.onSecondaryContainer;
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.on(context),
        icon: const Icon(Icons.add_rounded),
        focused: focused,
        loading: loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: const SearchResultTitle(title: "Create Organization"),
      suffix: SearchResultSuffix(
        label: "command",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
