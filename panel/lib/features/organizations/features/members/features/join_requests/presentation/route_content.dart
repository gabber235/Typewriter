import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_list.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

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
          padding: const EdgeInsets.all(16.0),
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
                const SizedBox(width: 12),
                ShimmerBox.rectangle(width: 76, height: 16),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: context.responsive(mobile: 3, tablet: 4, desktop: 7),
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(16),
      child: context.isDesktop
          ? Row(
              children: [
                const ShimmerBox.circle(width: 48, height: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      ShimmerBox.rectangle(width: 180, height: 16),
                      ShimmerBox.rectangle(width: 220, height: 14),
                    ],
                  ),
                ),
                const ShimmerBox.stadium(width: 76, height: 24),
                const SizedBox(width: 16),
                const ShimmerBox.stadium(width: 110, height: 40),
                const SizedBox(width: 8),
                const ShimmerBox.stadium(width: 102, height: 40),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerBox.circle(width: 40, height: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          ShimmerBox.rectangle(width: 140, height: 15),
                          ShimmerBox.rectangle(width: 200, height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerBox.stadium(width: 76, height: 24),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: ShimmerBox.stadium(height: 40)),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBox.stadium(height: 40)),
                  ],
                ),
              ],
            ),
    );
  }
}
