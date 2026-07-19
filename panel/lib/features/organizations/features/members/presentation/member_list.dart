import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
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
                            onRemove: () async {
                              await showConfirmationDialogue(
                                context: context,
                                title:
                                    "Remove ${selectedIds.value.length} member(s)?",
                                content:
                                    "Are you sure you want to remove these members from the organization?",
                                confirmText: "Remove",
                                confirmIcon: Fa6Solid.user_minus,
                                onConfirm: () async {
                                  for (final id in selectedIds.value) {
                                    await ref
                                        .read(
                                          organizationMembersProvider.notifier,
                                        )
                                        .removeMember(id);
                                  }
                                  selectedIds.value = {};
                                },
                              );
                            },
                            onClearSelection: () => selectedIds.value = {},
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        membersAsync(
          name: "Members",
          builder: (members) => SliverStaggerScope(
            sliver: context.isDesktop
                ? MembersTable(members: members, selectedIds: selectedIds)
                : MembersTabletList(members: members, selectedIds: selectedIds),
          ),
          loading: (_) => const _MembersLoadingShimmer(),
          error: (title, message) => SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                SizedBox(width: 12),
                ShimmerBox.rectangle(width: 72, height: 14),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: context.responsive(mobile: 6, tablet: 8),
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ShimmerBox.circle(width: 40, height: 40),
            SizedBox(width: 12),
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
            SizedBox(width: 12),
            ShimmerBox.rectangle(width: 24, height: 24),
          ],
        ),
      ),
    );
  }
}
