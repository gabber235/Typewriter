import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates visible request rows and their transient multi selection.
///
/// The input list is the provider's read model. This widget owns only selected
/// identifiers and list animation. It keeps selection intersected with visible
/// requests. Bulk decline holds over the selected requests of the list's rows
/// and tries every request; each refusal shows under its row.
class JoinRequestsList extends HookConsumerWidget {
  const JoinRequestsList({required this.requests, super.key});

  final List<skir.OrganizationJoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = useState<Set<skir.RecordId>>({});
    final theme = Theme.of(context);
    // One rows handle for the list and the bulk bar's decline hold.
    final rows = useAnimatedRows(
      items: requests,
      identity: (request) => request.requestId,
    );
    String? nameOf(skir.RecordId id) =>
        rows[id]?.item.userName ?? rows[id]?.item.userEmail;
    final decline = joinRequestDecline(
      id: "decline_bulk_join_requests_key",
      label: "Decline requests",
      priority: 2,
      targets: () => selectedIds.value.intersection({
        for (final request in rows.items) request.requestId,
      }),
      nameOf: nameOf,
      rows: rows,
    );

    useEffect(() {
      final requestIds = requests.map((request) => request.requestId).toSet();
      final validSelection = selectedIds.value.intersection(requestIds);

      if (validSelection.length == selectedIds.value.length) return null;
      selectedIds.value = validSelection;
      return null;
    }, [requests, selectedIds]);

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

    return SliverMainAxisGroup(
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
              spacing: context.spacing.space2,
              crossAxisAlignment: context.responsive(
                mobile: CrossAxisAlignment.start,
                tablet: CrossAxisAlignment.center,
              ),
              children: [
                Enter(
                  token: MotionToken.loadIn,
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
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
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
                    decline: decline,
                  )
                else
                  Flexible(
                    child: BulkJoinRequestActions(
                      selectedCount: selectedIds.value.length,
                      selectedIds: selectedIds.value,
                      onClearSelection: () => selectedIds.value = {},
                      decline: decline,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverAnimatedRows(
          rows: rows,
          itemBuilder: (context, entry) =>
              _child(context, entry.item, selectedIds, rows, nameOf),
        ),
      ],
    );
  }

  Widget _child(
    BuildContext context,
    skir.OrganizationJoinRequest request,
    ValueNotifier<Set<skir.RecordId>> selectedIds,
    AnimatedRows<skir.OrganizationJoinRequest> rows,
    String? Function(skir.RecordId request) nameOf,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.space3),
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
        rows: rows,
        selectedIds: selectedIds.value,
        nameOf: nameOf,
      ),
    );
  }
}
