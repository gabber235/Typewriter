import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/skir.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/organization_icon.dart";
import "package:typewriter_panel/widgets/app/components/selector_popup.dart";

class OrganizationSelector extends HookConsumerWidget {
  const OrganizationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationsAsync = ref.watch(organizationsProvider);
    final selectedOrgAsync = ref.watch(organizationProvider);

    return SelectorPopupWithSelection<OrganizationData>(
      itemsAsync: organizationsAsync,
      selectedAsync: selectedOrgAsync,
      name: "organizations",
      buttonBuilder: (selected) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OrganizationLogo(logoUrl: selected.logoUrl, size: 24),
            ),
          Text(
            selected?.name.formatted ?? "Select Organization",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      contentBuilder: (organizations, selected, onDismiss) =>
          _OrganizationMenuContent(
            organizations: organizations,
            selectedOrganization: selected,
            onDismiss: onDismiss,
          ),
    );
  }
}

class _OrganizationMenuContent extends HookConsumerWidget {
  const _OrganizationMenuContent({
    required this.organizations,
    required this.selectedOrganization,
    required this.onDismiss,
  });

  final List<OrganizationData> organizations;
  final OrganizationData? selectedOrganization;
  final void Function(OrganizationData) onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState("");

    final filteredOrganizations = organizations.where((org) {
      if (searchQuery.value.isEmpty) return true;
      return org.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectorSearchField(
          searchQuery: searchQuery,
          hintText: "Search organizations",
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: _OrganizationsList(
                  organizations: filteredOrganizations,
                  onSelect: (org) {
                    ref
                        .read(appRouterProvider)
                        .navigate(
                          OrganizationRoute(
                            organizationId: org.organizationId.id,
                          ),
                        );
                    onDismiss(org);
                  },
                ),
              ),
              if (selectedOrganization != null)
                _OrganizationActions(
                  organization: selectedOrganization!,
                  onDismiss: () {
                    if (selectedOrganization != null) {
                      onDismiss(selectedOrganization!);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrganizationsList extends StatelessWidget {
  const _OrganizationsList({
    required this.organizations,
    required this.onSelect,
  });

  final List<OrganizationData> organizations;
  final void Function(OrganizationData) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SelectorSectionHeader(title: "Organizations"),
        Flexible(
          child: ListView.builder(
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final org = organizations[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    dense: true,
                    leading: OrganizationLogo(logoUrl: org.logoUrl, size: 32),
                    title: Text(
                      org.name.formatted,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => onSelect(org),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrganizationActions extends HookConsumerWidget {
  const _OrganizationActions({
    required this.organization,
    required this.onDismiss,
  });

  final OrganizationData organization;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionList(
      title: "Actions",
      actions: [
        ActionItem(
          icon: Icons.group,
          title: "Manage Members",
          onTap: () {
            onDismiss();
            ref
                .read(appRouterProvider)
                .navigate(
                  OrganizationRoute(
                    organizationId: organization.organizationId.id,
                    children: [MembersRoute()],
                  ),
                );
          },
        ),
      ],
    );
  }
}

class ActionItem {
  const ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class ActionList extends StatelessWidget {
  const ActionList({required this.title, required this.actions, super.key});

  final String title;
  final List<ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...actions.map(
          (action) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              leading: Icon(action.icon, size: 16),
              title: Text(
                action.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              onTap: action.onTap,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
