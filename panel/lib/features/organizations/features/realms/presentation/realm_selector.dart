import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/application/router/app_router.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/realm.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector_popup.dart";
import "package:typewriter_panel/features/organizations/features/services/application/services.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/shared/ui/components/status_indicator.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/color.dart";

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
            color: selected?.color ?? Colors.grey,
          ),
          const SizedBox(width: 8),
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
                  borderRadius: BorderRadius.circular(8),
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
                        dotColor: _statusDotColor(
                          context,
                          realm.isOnline,
                          isSelected,
                        ),
                        textColor: _statusTextColor(
                          context,
                          realm.isOnline,
                          isSelected,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: isSelected ? Colors.white : null,
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
        const SizedBox(height: 8),
      ],
    );
  }
}

Color _statusDotColor(BuildContext context, bool isOnline, bool isSelected) {
  return switch ((isOnline, isSelected)) {
    (true, false) => Colors.green,
    (true, true) => Colors.white,
    (false, false) => Colors.grey,
    (false, true) => Surface.colorOf(context).withValues(alpha: 0.5),
  };
}

Color _statusTextColor(BuildContext context, bool isOnline, bool isSelected) {
  final theme = Theme.of(context);
  return switch ((isOnline, isSelected)) {
    (true, _) => Colors.white.withValues(alpha: 0.7),
    (false, false) => theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    (false, true) => Surface.colorOf(context).withValues(alpha: 0.5),
  };
}
