import "package:flutter/material.dart";
import "package:typewriter_panel/logic/organization/members.dart";

/// A component that displays role selection as FilterChips in a Wrap layout.
///
/// This is used for mobile/tablet views where inline chip selection is
/// preferred over a dropdown. Used in:
/// - Join request approval (selecting roles for new member)
/// - Member role editing on mobile views
class RoleMultiselectChips extends StatelessWidget {
  const RoleMultiselectChips({
    required this.availableRoles,
    required this.selectedRoles,
    required this.onRolesChanged,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    super.key,
  });

  /// All available roles to select from.
  final List<MemberRole> availableRoles;

  /// Currently selected roles.
  final List<MemberRole> selectedRoles;

  /// Called when the selection changes.
  final ValueChanged<List<MemberRole>> onRolesChanged;

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
                : selectedRoles.where((r) => r.id != role.id).toList();
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

  final MemberRole role;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(role.name),
      labelStyle: TextStyle(
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
