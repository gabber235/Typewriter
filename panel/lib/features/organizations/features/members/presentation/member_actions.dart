import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class BulkMemberActions extends HookConsumerWidget {
  const BulkMemberActions({
    required this.selectedCount,
    required this.selectedIds,
    required this.onRemove,
    required this.onClearSelection,
    super.key,
  });

  final int selectedCount;
  final Set<skir.RecordId> selectedIds;
  final VoidCallback onRemove;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bulkRoles = useState<List<OrganizationRole>>([]);

    final roleDropdown = RoleMultiselectDropdown(
      selectedRoles: bulkRoles.value,
      onRolesChanged: (roles) => bulkRoles.value = roles,
      placeholder: "Assign roles",
    );

    return Flex(
      direction: context.responsive(
        mobile: Axis.vertical,
        tablet: Axis.horizontal,
      ),
      spacing: 4,
      crossAxisAlignment: context.responsive(
        mobile: CrossAxisAlignment.start,
        tablet: CrossAxisAlignment.center,
      ),
      children: [
        SelectedChip(
          selectedCount: selectedCount,
          onClearSelection: onClearSelection,
        ),

        if (context.isMobile) roleDropdown else Flexible(child: roleDropdown),

        // Apply bulk roles button
        if (bulkRoles.value.isNotEmpty)
          FilledButton.icon(
            onPressed: () async {
              for (final id in selectedIds) {
                await ref
                    .read(organizationMembersProvider.notifier)
                    .updateMemberRoles(id, bulkRoles.value)
                    .catchApiExceptionsAndDisplay(context);
              }
              bulkRoles.value = [];
              onClearSelection();
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text("Apply"),
          ),
        OutlinedButton.icon(
          onPressed: onRemove,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          icon: const Icon(Icons.person_remove_outlined, size: 18),
          label: const Text("Remove"),
        ),
      ],
    );
  }
}

/// Row actions for a member (remove button).
