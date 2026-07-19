import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class MembersTab extends HookConsumerWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(organizationMembersProvider);
    final selectedIds = useState<Set<skir.RecordId>>({});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              Text("Current Members", style: theme.textTheme.titleMedium),
              if (selectedIds.value.isNotEmpty)
                BulkMemberActions(
                  selectedCount: selectedIds.value.length,
                  selectedIds: selectedIds.value,
                  onRemove: () async {
                    final confirmed = await showConfirmationDialogue(
                      context: context,
                      title: "Remove ${selectedIds.value.length} member(s)?",
                      content:
                          "Are you sure you want to remove these members from the organization?",
                      confirmText: "Remove",
                      confirmIcon: Fa6Solid.user_minus,
                      onConfirm: () async {
                        for (final id in selectedIds.value) {
                          await ref
                              .read(organizationMembersProvider.notifier)
                              .removeMember(id);
                        }
                        selectedIds.value = {};
                      },
                    );
                    if (!confirmed) return;
                  },
                  onClearSelection: () => selectedIds.value = {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        membersAsync(
          name: "Members",
          builder: (members) => context.isDesktop
              ? MembersTable(members: members, selectedIds: selectedIds)
              : MembersTabletList(members: members, selectedIds: selectedIds),
          loading: (name) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LoadingIndicator(message: "Loading $name..."),
            ),
          ),
          error: (title, message) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ErrorScreen.small(title: title, message: message),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
