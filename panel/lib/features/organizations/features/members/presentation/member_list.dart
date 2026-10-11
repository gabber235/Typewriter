import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates the live member projection with shared selection state.
///
/// Selection is local UI state and is intersected with the latest member ids so
/// removed or stale rows cannot remain actionable. Durable role and removal
/// operations go through [OrganizationMembers], while this widget chooses the
/// table or tablet list and presents loading and provider error states.
class MembersTab extends HookConsumerWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(organizationMembersProvider);
    final selectedIds = useState<Set<skir.RecordId>>({});
    final liveMembers = useRef<List<OrganizationMember>>([]);
    final isRemovingSelection = useRef(false);

    useEffect(() {
      final memberIds = liveMembers.value
          .map((member) => member.userId)
          .toSet();
      final validSelection = selectedIds.value.intersection(memberIds);
      if (validSelection.length == selectedIds.value.length) return null;
      selectedIds.value = validSelection;
      return null;
    }, [liveMembers.value, selectedIds.value]);

    Future<void> removeSelection() async {
      if (isRemovingSelection.value) return;
      final memberIds = liveMembers.value
          .map((member) => member.userId)
          .toSet();
      final idsToRemove = selectedIds.value.intersection(memberIds);
      if (idsToRemove.isEmpty) {
        selectedIds.value = {};
        return;
      }

      isRemovingSelection.value = true;
      try {
        await showConfirmationDialogue(
          context: context,
          title: "Remove ${idsToRemove.length} member(s)?",
          content: "Are you sure you want to remove these members from the organization?",
          confirmText: "Remove",
          confirmIcon: Fa6Solid.user_minus,
          onConfirm: () async {
            final succeeded = <skir.RecordId>{};
            for (final id in idsToRemove) {
              try {
                await ref.executeMembership(
                  ref.membershipCommands.remove(id),
                  (response) => response.requireAccepted(),
                );
                succeeded.add(id);
              } on ApiException catch (error) {
                if (context.mounted) showErrorSnackBar(context, error.message);
              } on SubmissionException {
                continue;
              }
            }
            if (context.mounted) {
              selectedIds.value = selectedIds.value.difference(succeeded);
            }
          },
        );
      } finally {
        isRemovingSelection.value = false;
      }
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Text(
                  "Current Members",
                  style: theme.textTheme.titleMedium,
                ),
              ),
              PinnedHeaderSliver(
                child: AnimatedSize(
                  duration: 800.ms,
                  alignment: .topLeft,
                  curve: ElasticOutCurve(0.9),
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: selectedIds.value.isEmpty
                        ? const SizedBox.shrink()
                        : BulkMemberActions(
                            selectedCount: selectedIds.value.length,
                            selectedIds: selectedIds.value,
                            onRemove: removeSelection,
                            onUnselect: (ids) => selectedIds.value = selectedIds
                                .value
                                .difference(ids),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        membersAsync(
          name: "Members",
          builder: (members) {
            liveMembers.value = members;
            return SliverStaggerScope(
              sliver: context.isDesktop
                  ? MembersTable(
                      members: members,
                      selectedIds: selectedIds,
                      onRemoveSelection: removeSelection,
                    )
                  : MembersTabletList(
                      members: members,
                      selectedIds: selectedIds,
                      onRemoveSelection: removeSelection,
                    ),
            );
          },
          loading: (_) => const _MembersLoadingShimmer(),
          error: (title, message) => SliverFillRemaining(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space4),
              child: Center(
                child: ErrorScreen(title: title, message: message),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps the loading placeholder aligned with the eventual responsive layout.
class _MembersLoadingShimmer extends StatelessWidget {
  const _MembersLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return const _MembersTableShimmer(key: ValueKey("membersLoadingDesktop"));
    }

    return const _MembersListShimmer(key: ValueKey("membersLoadingMobile"));
  }
}

class _MembersTableShimmer extends StatelessWidget {
  const _MembersTableShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Surface(
        color: Surface.colorOf(context),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(48),
            1: IntrinsicColumnWidth(),
            2: FlexColumnWidth(1),
            3: FixedColumnWidth(80),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _MembersTableCell(
                  child: ShimmerBox.rectangle(width: 24, height: 24),
                ),
                _MembersTableCell(
                  child: ShimmerBox.rectangle(width: 64, height: 13),
                ),
                _MembersTableCell(
                  child: ShimmerBox.rectangle(width: 48, height: 13),
                ),
                SizedBox.shrink(),
              ],
            ),
            for (var index = 0; index < 9; index++)
              TableRow(
                children: [
                  _MembersTableCell(
                    child: ShimmerBox.circle(width: 32, height: 32),
                  ),
                  _MembersTableCell(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        ShimmerBox.rectangle(width: 136, height: 14),
                        ShimmerBox.rectangle(width: 200, height: 12),
                      ],
                    ),
                  ),
                  _MembersTableCell(
                    child: SizedBox(
                      width: double.infinity,
                      child: ShimmerBox.rectangle(height: 48),
                    ),
                  ),
                  _MembersTableCell(
                    child: Center(
                      child: ShimmerBox.circle(width: 20, height: 20),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MembersTableCell extends StatelessWidget {
  const _MembersTableCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: context.spacing.space3,
      ),
      child: child,
    );
  }
}

class _MembersListShimmer extends StatelessWidget {
  const _MembersListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                ShimmerBox.rectangle(width: 24, height: 24),
                SizedBox(width: context.spacing.space3),
                ShimmerBox.rectangle(width: 72, height: 14),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: context.responsive(mobile: 6, tablet: 8),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: context.spacing.space3),
            child: _MemberCardShimmer(),
          ),
        ),
      ],
    );
  }
}

class _MemberCardShimmer extends StatelessWidget {
  const _MemberCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Surface(
      color: Surface.colorOf(context),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: Row(
          children: [
            ShimmerBox.circle(width: 40, height: 40),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  ShimmerBox.rectangle(width: 140, height: 15),
                  ShimmerBox.rectangle(width: 210, height: 13),
                ],
              ),
            ),
            SizedBox(width: context.spacing.space3),
            ShimmerBox.rectangle(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
