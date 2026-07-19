import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/application/application.dart";
import "package:typewriter_panel/shared/ui/components/multiselect_dropdown.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

class RoleMultiselectDropdown extends HookConsumerWidget {
  const RoleMultiselectDropdown({
    required this.selectedRoles,
    required this.onRolesChanged,
    required this.placeholder,
    super.key,
  });

  final List<OrganizationRole> selectedRoles;
  final ValueChanged<List<OrganizationRole>> onRolesChanged;
  final String? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(organizationRolesProvider);
    final focusNode = useFocusNode();
    return rolesAsync(
      name: "Roles",
      builder: (availableRoles) {
        return MultiselectDropdown<OrganizationRole>(
          focusNode: focusNode,
          dropdownMenuEntries: [
            for (final role in availableRoles)
              DropdownMenuEntry(
                value: role,
                label: role.name,
                labelWidget: _roleMenuEntry(context, role),
                enabled: role.assignable,
              ),
          ],
          selectedItems: selectedRoles,
          onSelectionChanged: onRolesChanged,
          placeholder: placeholder,
          itemBuilder: (role) => SmallChip(
            label: role.name,
            color: role.color,
            onDelete: role.assignable
                ? () {
                    onRolesChanged(
                      selectedRoles
                          .where((r) => r.roleId != role.roleId)
                          .toList(),
                    );
                  }
                : null,
          ),
        );
      },
      loading: (_) => ShimmerBox.stadium(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _roleMenuEntry(BuildContext context, OrganizationRole role) {
    final isSelected = selectedRoles.contains(role);
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: role.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(role.name),
        const Spacer(),
        if (isSelected)
          Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
      ],
    );
  }
}
