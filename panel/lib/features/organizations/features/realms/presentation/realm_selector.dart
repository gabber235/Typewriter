import "package:typewriter_panel/typewriter_panel.dart";

/// Lets the user switch the organization workspace to another realm.
///
/// The topology provider supplies the selectable projection and the route remains
/// the selection authority. Choosing an item navigates first, so all dependent
/// providers rebuild for the new realm and the old catalog and session can be
/// disposed by Riverpod.
class RealmSelector extends HookConsumerWidget {
  const RealmSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(realmsProvider);
    final selectedRealmAsync = ref.watch(selectedRealmProvider);

    return SelectorPopupWithSelection<TopologyRealm>(
      itemsAsync: realmsAsync,
      selectedAsync: selectedRealmAsync,
      name: "realms",
      buttonBuilder: (selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud,
            size: 16,
            color: selected == null
                ? context.colors.contentDisabled
                : realmServiceRoleColor,
          ),
          SizedBox(width: context.spacing.space2),
          Text(
            selected?.ownerHost.name.formatted ?? "Select Realm",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      contentBuilder: (realms, selected, onDismiss) => _RealmMenuContent(
        realms: realms,
        selectedRealm: selected,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Searchable menu body for the current topology projection.
class _RealmMenuContent extends HookConsumerWidget {
  const _RealmMenuContent({
    required this.realms,
    required this.selectedRealm,
    required this.onDismiss,
  });

  final List<TopologyRealm> realms;
  final TopologyRealm? selectedRealm;
  final void Function(TopologyRealm) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");

    final filteredRealms = realms.where((realm) {
      if (searchQuery.value.isEmpty) return true;
      return realm.ownerHost.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorSearchField(
          searchQuery: searchQuery,
          hintText: "Search realms",
        ),
        const SelectorSectionHeader(title: "Realms"),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredRealms.length,
            itemBuilder: (context, index) {
              final realm = filteredRealms[index];

              return _RealmMenuItem(
                realm: realm,
                isSelected: realm.realmId == selectedRealm?.realmId,
                onDismiss: onDismiss,
              );
            },
          ),
        ),
        SizedBox(height: context.spacing.space2),
      ],
    );
  }
}

/// Shows one realm's host identity and live topology status.
class _RealmMenuItem extends HookConsumerWidget {
  const _RealmMenuItem({
    required this.realm,
    required this.isSelected,
    required this.onDismiss,
  });

  final TopologyRealm realm;
  final bool isSelected;
  final void Function(TopologyRealm) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onColor = realmServiceRoleColor.on(context);
    final isOnline =
        realm.state.status == TopologyRuntimeStatus.active &&
        ref.watch(hostConnectedProvider(realm.ownerHost.id));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: 2,
      ),
      child: Material(
        borderRadius: context.shapes.mediumBorderRadius,
        color: isSelected ? realmServiceRoleColor : null,
        child: Surface(
          color: isSelected ? realmServiceRoleColor : Surface.colorOf(context),
          foreground: isSelected ? onColor : null,
          secondaryForeground: isSelected
              ? onColor.withValues(alpha: 0.7)
              : null,
          child: Builder(
            builder: (context) => ListTileTheme.merge(
              textColor: Surface.foregroundOf(context),
              iconColor: Surface.foregroundOf(context),
              child: ListTile(
                dense: true,
                leading: Icon(
                  Icons.cloud,
                  size: 20,
                  color: isSelected ? null : realmServiceRoleColor,
                ),
                title: Text(
                  realm.ownerHost.name.formatted,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 14),
                ),
                subtitle: StatusIndicator(
                  isOnline: isOnline,
                  lastSeen: realm.state.updatedAt,
                  dotColor: isSelected
                      ? onColor
                      : _statusDotColor(context, isOnline),
                  textColor: Surface.secondaryForegroundOf(context),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  final orgId = ref.read(organizationIdProvider);
                  if (orgId == null) return;
                  context.router.navigate(
                    OrganizationRoute(
                      organizationId: orgId.id,
                      children: [RealmRoute(realmId: realm.realmId.id)],
                    ),
                  );
                  onDismiss(realm);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusDotColor(BuildContext context, bool isOnline) =>
    isOnline ? context.colors.online : context.colors.offline;
