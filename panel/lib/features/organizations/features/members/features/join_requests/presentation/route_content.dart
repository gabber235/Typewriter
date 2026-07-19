import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/application.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/presentation/join_request_list.dart";
import "package:typewriter_panel/shared/ui/components/loading_indicator.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
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
      loading: (name) => SliverToBoxAdapter(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LoadingIndicator(message: "Loading $name..."),
          ),
        ),
      ),
      error: (title, message) => SliverToBoxAdapter(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ErrorScreen.small(title: title, message: message),
            ),
          ),
        ),
      ),
    );
  }
}
