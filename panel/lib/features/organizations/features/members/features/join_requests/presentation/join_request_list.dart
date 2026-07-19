import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_actions.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_card.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/empty_state.dart";

class JoinRequestsList extends HookConsumerWidget {
  const JoinRequestsList({required this.requests, super.key});

  final List<OrganizationJoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = useState<Set<skir.RecordId>>({});
    final theme = Theme.of(context);

    if (requests.isEmpty) {
      return EmptyState(
        icon: Fa6Solid.user_plus,
        title: "No join requests",
        description: "When members request to join, they will appear here.",
      );
    }

    final allSelected =
        requests.isNotEmpty && selectedIds.value.length == requests.length;
    final someSelected =
        selectedIds.value.isNotEmpty &&
        selectedIds.value.length < requests.length;

    void handleSelectAll() {
      if (allSelected || someSelected) {
        selectedIds.value = {};
      } else {
        selectedIds.value = requests.map((r) => r.requestId).toSet();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          direction: .horizontal,
          alignment: .spaceBetween,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: handleSelectAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: allSelected ? true : (someSelected ? null : false),
                    tristate: true,
                    onChanged: (value) => handleSelectAll(),
                  ),
                  Text(
                    "Select all",
                    style: TextStyle(
                      fontVariations: [.weight(500)],
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selectedIds.value.isNotEmpty)
              BulkJoinRequestActions(
                selectedCount: selectedIds.value.length,
                selectedIds: selectedIds.value,
                onClearSelection: () => selectedIds.value = {},
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...requests.asMap().entries.map((entry) {
          final index = entry.key;
          final request = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JoinRequestCard(
              key: ValueKey(request.requestId),
              request: request,
              index: index,
              isSelected: selectedIds.value.contains(request.requestId),
              onSelectionChanged: (selected) {
                if (selected) {
                  selectedIds.value = {...selectedIds.value, request.requestId};
                } else {
                  selectedIds.value = selectedIds.value
                      .where((id) => id != request.requestId)
                      .toSet();
                }
              },
            ),
          );
        }),
      ],
    );
  }
}
