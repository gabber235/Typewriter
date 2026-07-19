import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

class JoinRequestsList extends HookConsumerWidget {
  const JoinRequestsList({required this.requests, super.key});

  final List<OrganizationJoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = useState<Set<skir.RecordId>>({});
    final theme = Theme.of(context);
    final isDecliningSelection = useRef(false);

    Future<void> declineSelection() async {
      if (isDecliningSelection.value) return;
      final requestIds = requests.map((request) => request.requestId).toSet();
      final idsToDecline = selectedIds.value.intersection(requestIds);
      if (idsToDecline.isEmpty) {
        selectedIds.value = {};
        return;
      }

      isDecliningSelection.value = true;
      try {
        await showConfirmationDialogue(
          context: context,
          title: "Decline ${idsToDecline.length} request(s)?",
          content: "Are you sure you want to decline these join requests?",
          confirmText: "Decline All",
          confirmIcon: Fa6Solid.xmark,
          onConfirm: () async {
            for (final id in idsToDecline) {
              await ref
                  .read(organizationJoinRequestsProvider.notifier)
                  .declineRequest(id);
            }
            selectedIds.value = {};
          },
        );
      } finally {
        isDecliningSelection.value = false;
      }
    }

    useEffect(() {
      final requestIds = requests.map((request) => request.requestId).toSet();
      final validSelection = selectedIds.value.intersection(requestIds);

      if (validSelection.length == selectedIds.value.length) return null;
      selectedIds.value = validSelection;
      return null;
    }, [requests, selectedIds]);

    final animation = useSliverAnimatedList(
      items: requests,
      identity: (item) => item.requestId,
      removedItemBuilder: (context, item, animation) => _child(
        item,
        selectedIds,
        declineSelection,
        animation,
        deleting: true,
      ),
    );

    if (requests.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Fa6Solid.user_plus,
          title: "No join requests",
          description: "When members request to join, they will appear here.",
        ),
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

    return SliverStaggerScope(
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverFloatingHeader(
            child: Container(
              color: Surface.colorOf(context),
              padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
              child: Flex(
                direction: context.responsive(
                  mobile: Axis.vertical,
                  tablet: Axis.horizontal,
                ),
                spacing: 8,
                crossAxisAlignment: context.responsive(
                  mobile: CrossAxisAlignment.start,
                  tablet: CrossAxisAlignment.center,
                ),
                children: [
                  StaggerEntrance(
                    child: SizedBox(
                      height: 52,
                      child: GestureDetector(
                        onTap: handleSelectAll,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: allSelected
                                  ? true
                                  : (someSelected ? null : false),
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
                    ),
                  ),
                  if (context.isMobile)
                    BulkJoinRequestActions(
                      selectedCount: selectedIds.value.length,
                      selectedIds: selectedIds.value,
                      onClearSelection: () => selectedIds.value = {},
                      onDecline: declineSelection,
                    )
                  else
                    Flexible(
                      child: BulkJoinRequestActions(
                        selectedCount: selectedIds.value.length,
                        selectedIds: selectedIds.value,
                        onClearSelection: () => selectedIds.value = {},
                        onDecline: declineSelection,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverAnimatedList(
            key: animation.key,
            initialItemCount: animation.items.length,
            itemBuilder: (context, index, animation) {
              final request = requests[index];
              return _child(request, selectedIds, declineSelection, animation);
            },
          ),
        ],
      ),
    );
  }

  Widget _child(
    OrganizationJoinRequest request,
    ValueNotifier<Set<skir.RecordId>> selectedIds,
    Future<void> Function() onDeclineSelection,
    Animation<double> animation, {
    bool deleting = false,
  }) {
    return ExcludeInteraction(
      key: ValueKey(request.requestId),
      excluding: deleting,
      child: ElasticTransition(
        animation: animation,
        child: StaggerEntrance(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JoinRequestCard(
              request: request,
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
              onSelectAll: () => selectedIds.value = requests
                  .map((request) => request.requestId)
                  .toSet(),
              onClearSelection: () => selectedIds.value = {},
              hasSelection: selectedIds.value.isNotEmpty,
              onDeclineSelection: onDeclineSelection,
            ),
          ),
        ),
      ),
    );
  }
}
