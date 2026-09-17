import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders a topology realm with its host identity and runtime status.
class RealmSearchResultItem extends HookConsumerWidget {
  const RealmSearchResultItem({
    required this.realm,
    this.selected = false,
    this.focused = false,
    this.loading = false,
    this.onTap,
    this.shortcutActivator,
    super.key,
  });

  factory RealmSearchResultItem.realm({
    required TopologyRealm realm,
    bool selected = false,
    bool focused = false,
    bool loading = false,
    VoidCallback? onTap,
    ShortcutActivator? shortcutActivator,
    Key? key,
  }) {
    return RealmSearchResultItem(
      realm: realm,
      selected: selected,
      focused: focused,
      loading: loading,
      onTap: onTap,
      shortcutActivator: shortcutActivator,
      key: key,
    );
  }

  final TopologyRealm realm;
  final bool selected;
  final bool focused;
  final bool loading;

  final VoidCallback? onTap;

  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(hostConnectedProvider(realm.ownerHost.id));
    final status = available
        ? childRuntimeStatusLabel(realm.state.status)
        : "Host offline";
    final tone = available
        ? topologyChildRuntimeStatusTone(realm.state.status)
        : TopologyStatusTone.offline;

    return SearchResultCard(
      color: realmServiceRoleColor,
      prefix: SearchResultIconTile(
        color: realmServiceRoleColor,
        onColor: realmServiceRoleColor.on(context),
        icon: const Icon(Icons.cloud_outlined),
        focused: focused,
        loading: loading,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: realm.ownerHost.name.formatted),
          TopologyStatusIndicator(
            label: status,
            tone: tone,
            color: realmServiceRoleColor,
            highlighted: focused,
          ),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "realm",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
