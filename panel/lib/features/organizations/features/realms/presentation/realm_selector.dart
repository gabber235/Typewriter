import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class RealmSelector extends HookConsumerWidget {
  const RealmSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realmsAsync = ref.watch(realmsProvider);
    final selectedRealmAsync = ref.watch(selectedRealmProvider);

    return SelectorPopupWithSelection<Service>(
      itemsAsync: realmsAsync,
      selectedAsync: selectedRealmAsync,
      name: "realms",
      buttonBuilder: (selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected?.icon ?? Icons.cloud,
            size: 16,
            color: selected?.color ?? context.colors.contentDisabled,
          ),
          SizedBox(width: context.spacing.space2),
          Text(
            selected?.displayName ?? "Select Realm",
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

class _RealmMenuContent extends HookConsumerWidget {
  const _RealmMenuContent({
    required this.realms,
    required this.selectedRealm,
    required this.onDismiss,
  });

  final List<Service> realms;
  final Service? selectedRealm;
  final void Function(Service) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");

    final filteredRealms = realms.where((realm) {
      if (searchQuery.value.isEmpty) return true;
      return realm.displayName.toLowerCase().contains(
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
              final isSelected = realm.serviceId == selectedRealm?.serviceId;

              final onColor = realm.color.on(context);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  borderRadius: context.shapes.mediumBorderRadius,
                  color: isSelected ? realm.color : null,
                  child: Surface(
                    color: isSelected ? realm.color : Surface.colorOf(context),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        realm.icon,
                        size: 20,
                        color: isSelected ? onColor : realm.color,
                      ),
                      title: Text(
                        realm.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: isSelected ? onColor : null,
                        ),
                      ),
                      subtitle: StatusIndicator(
                        isOnline: realm.isOnline,
                        lastSeen: realm.lastSeen,
                        dotColor: isSelected
                            ? onColor
                            : _statusDotColor(context, realm.isOnline),
                        textColor: isSelected
                            ? onColor.withValues(alpha: 0.7)
                            : _statusTextColor(context, realm.isOnline),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isSelected ? onColor : null,
                      ),
                      onTap: () {
                        final orgId = ref.read(organizationIdProvider);
                        if (orgId == null) return;
                        context.router.navigate(
                          OrganizationRoute(
                            organizationId: orgId.id,
                            children: [RealmRoute(realmId: realm.serviceId.id)],
                          ),
                        );
                        onDismiss(realm);
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.spacing.space2),
      ],
    );
  }
}

Color _statusDotColor(BuildContext context, bool isOnline) =>
    isOnline ? context.colors.online : context.colors.offline;

Color _statusTextColor(BuildContext context, bool isOnline) =>
    context.colors.contentSecondary;
