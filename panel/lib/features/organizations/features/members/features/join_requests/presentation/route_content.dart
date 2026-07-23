import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class JoinRequestsTab extends HookConsumerWidget {
  const JoinRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(organizationJoinRequestsProvider);

    return requestsAsync(
      name: "Join Requests",
      shrink: true,
      builder: (requests) => JoinRequestsList(requests: requests),
      loading: (_) => const _JoinRequestsShimmer(),
      error: (title, message) => SliverFillRemaining(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space4),
          child: Center(
            child: ErrorScreen(title: title, message: message),
          ),
        ),
      ),
    );
  }
}

class _JoinRequestsShimmer extends StatelessWidget {
  const _JoinRequestsShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 76,
            child: Row(
              children: [
                ShimmerBox.rectangle(width: 24, height: 24),
                SizedBox(width: context.spacing.space3),
                ShimmerBox.rectangle(width: 76, height: 16),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: context.responsive(mobile: 3, tablet: 4, desktop: 7),
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: context.spacing.space3),
            child: _JoinRequestCardShimmer(),
          ),
        ),
      ],
    );
  }
}

class _JoinRequestCardShimmer extends StatelessWidget {
  const _JoinRequestCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.space4),
      child: context.isDesktop
          ? Row(
              children: [
                const ShimmerBox.circle(width: 48, height: 48),
                SizedBox(width: context.spacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: context.spacing.space2,
                    children: [
                      ShimmerBox.rectangle(width: 180, height: 16),
                      ShimmerBox.rectangle(width: 220, height: 14),
                    ],
                  ),
                ),
                const ShimmerBox.stadium(width: 76, height: 24),
                SizedBox(width: context.spacing.space4),
                const ShimmerBox.stadium(width: 110, height: 40),
                SizedBox(width: context.spacing.space2),
                const ShimmerBox.stadium(width: 102, height: 40),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerBox.circle(width: 40, height: 40),
                    SizedBox(width: context.spacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: context.spacing.space2,
                        children: [
                          ShimmerBox.rectangle(width: 140, height: 15),
                          ShimmerBox.rectangle(width: 200, height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.spacing.space3),
                const ShimmerBox.stadium(width: 76, height: 24),
                SizedBox(height: context.spacing.space3),
                Row(
                  children: [
                    const Expanded(child: ShimmerBox.stadium(height: 40)),
                    SizedBox(width: context.spacing.space2),
                    Expanded(child: ShimmerBox.stadium(height: 40)),
                  ],
                ),
              ],
            ),
    );
  }
}
