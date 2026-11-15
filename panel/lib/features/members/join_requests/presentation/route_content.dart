import "package:typewriter_panel/typewriter_panel.dart";

/// Bridges the live moderation projection into route content states.
///
/// Loading and failures stay at the projection boundary. Once data exists,
/// [JoinRequestsList] owns transient selection while this widget remains a
/// provider consumer only.
class JoinRequestsTab extends HookConsumerWidget {
  const JoinRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(visibleOrganizationJoinRequestsProvider);

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
    return SliverSemantics(
      label: "Loading join requests",
      container: true,
      sliver: SliverList.builder(
        itemCount: context.responsive(mobile: 3, tablet: 4, desktop: 7),
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: context.spacing.space3),
          child: const SelectionCardShimmer(
            trailing: ShimmerBox.stadium(width: 76, height: 24),
          ),
        ),
      ),
    );
  }
}
