import "package:typewriter_panel/typewriter_panel.dart";

/// Dropdown role editor for table and bulk member actions.
///
/// It observes the live role catalog, disables protected roles, and emits only
/// selection intent. The caller decides whether that intent targets one member
/// or a captured bulk selection and owns mutation errors.
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
    final field = useInputFieldController(inputDebugLabel: "Member roles");
    return rolesAsync(
      name: "Roles",
      builder: (availableRoles) {
        return MultiselectDropdown<OrganizationRole>(
          inputFieldController: field,
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
        SizedBox(width: context.spacing.space2),
        Text(role.name),
        const Spacer(),
        if (isSelected)
          Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
      ],
    );
  }
}
