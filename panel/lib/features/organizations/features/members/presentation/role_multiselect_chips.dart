import "package:typewriter_panel/typewriter_panel.dart";

/// Inline role editor for compact member surfaces.
///
/// The catalog remains the source of available roles. Non assignable roles are
/// rendered but disabled, preserving protected role visibility while keeping
/// ordinary membership edits inside the assignable role boundary. The callback
/// receives a new selection and does not perform persistence itself.
class RoleMultiselectChips extends StatelessWidget {
  const RoleMultiselectChips({
    required this.availableRoles,
    required this.selectedRoles,
    required this.onRolesChanged,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    super.key,
  });

  /// The current role catalog, including protected roles that cannot be edited.
  final List<OrganizationRole> availableRoles;

  /// Roles currently projected onto the member or draft selection.
  final List<OrganizationRole> selectedRoles;

  /// Receives the requested selection. The owning provider decides whether and
  /// how to persist it.
  final ValueChanged<List<OrganizationRole>> onRolesChanged;

  /// Horizontal spacing between chips.
  final double spacing;

  /// Vertical spacing between chip rows.
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: availableRoles.map((role) {
        final isSelected = selectedRoles.contains(role);
        return _RoleFilterChip(
          role: role,
          isSelected: isSelected,
          onSelected: (selected) {
            final newRoles = selected
                ? [...selectedRoles, role]
                : selectedRoles.where((r) => r.roleId != role.roleId).toList();
            onRolesChanged(newRoles);
          },
        );
      }).toList(),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.role,
    required this.isSelected,
    required this.onSelected,
  });

  final OrganizationRole role;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(role.name),
      labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
        color: isSelected
            ? role.color
            : Theme.of(context).colorScheme.onSurface,
      ),
      selected: isSelected,
      onSelected: role.assignable ? onSelected : null,
      tooltip: role.assignable
          ? isSelected
                ? "Remove ${role.name}"
                : "Assign ${role.name}"
          : "${role.name} is not assignable",
      selectedColor: role.color.withValues(alpha: 0.2),
      showCheckmark: false,
      avatar: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: role.color, shape: BoxShape.circle),
      ),
      side: BorderSide(
        color: isSelected
            ? role.color.withValues(alpha: 0.5)
            : Colors.transparent,
      ),
    );
  }
}
