import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Shows the live member projection as the window allows: a table, or a
/// list of cards on narrow windows, and its loading and failure states.
///
/// Members are selected through the shared selection; the inspector shows
/// and edits the selected members. The tab publishes its rows, so a remove
/// held from the inspector or the context menu sends and refuses on them,
/// and members that leave the live list leave the selection by the
/// selection's own rule.
class MembersTab extends HookConsumerWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(organizationMembersProvider);
    // One rows handle per tab, above the data builder: the table and the
    // card list share it. Members present when the data first arrives join
    // the load run.
    final rows = useAnimatedRows(
      items: membersAsync.value ?? const <skir.OrganizationMember>[],
      identity: (member) => member.userId,
      ready: membersAsync.hasValue,
    );
    ref.useMembershipRows(list: MembershipList.members, rows: rows);

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
          sliver: SliverToBoxAdapter(
            child: Text("Current Members", style: theme.textTheme.titleMedium),
          ),
        ),
        membersAsync(
          name: "Members",
          builder: (members) => context.isDesktop
              ? MembersTable(rows: rows)
              : MembersCardList(rows: rows),
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
  Widget build(BuildContext context) => SliverSemantics(
    label: "Loading members",
    container: true,
    sliver: context.isDesktop
        ? const _MembersTableShimmer()
        : const _MembersListShimmer(),
  );
}

class _MembersTableShimmer extends StatelessWidget {
  const _MembersTableShimmer();

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
                SizedBox.shrink(),
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
  const _MembersListShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: context.responsive(mobile: 6, tablet: 8),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: context.spacing.space3),
        child: const SelectionCardShimmer(),
      ),
    );
  }
}
