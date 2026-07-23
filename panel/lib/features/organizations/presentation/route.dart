import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "create_organization.dart";
part "join_organization.dart";
part "organizations.dart";

@RoutePage()
class IndexPage extends ConsumerWidget {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizations = ref.watch(organizationsProvider);
    final joinRequests = ref.watch(userJoinRequestsProvider);

    final content = Center(
      child: organizations(
        name: "organizations",
        builder: (organizations) => joinRequests(
          name: "joinRequests",
          builder: (joinRequests) => Pane(
            id: "index",
            primary: true,
            highlightOnFocus: false,
            trapFocus: false,
            child: _IndexPageContent(
              organizations: organizations,
              joinRequests: joinRequests,
            ),
          ),
        ),
      ),
    );

    if (context.isSmallerThanOrEqualTo(.tablet)) {
      return SimpleScaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
          actions: [
            const FooterSidebarLinks(compact: true, expand: false),
            SizedBox(width: context.spacing.space2),
          ],
        ),
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        const Positioned(
          left: 8,
          bottom: 8,
          child: Pane(
            id: "footer",
            highlightOnFocus: false,
            trapFocus: false,
            child: FooterSidebarLinks(expand: false),
          ),
        ),
      ],
    );
  }
}

class _IndexPageContent extends StatelessWidget {
  const _IndexPageContent({
    required this.organizations,
    required this.joinRequests,
  });

  final List<OrganizationData> organizations;
  final List<UserJoinRequest> joinRequests;

  Widget get spacer => const SliverToBoxAdapter(child: SizedBox(height: 24));

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: CustomScrollView(
        primary: true,
        slivers: [
          SliverStaggerScope(
            sliver: CenteredSliverMainAxisGroup(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.space4,
                    vertical: context.spacing.space6,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      if (organizations.isNotEmpty) ...[
                        _OrganizationsSelector(organizations: organizations),
                        spacer,
                        const SliverStaggerEntrance(
                          sliver: SliverToBoxAdapter(child: LabeledDivider()),
                        ),
                        spacer,
                      ],
                      _JoinOrganization(joinRequests: joinRequests),
                      spacer,
                      const SliverStaggerEntrance(
                        sliver: SliverToBoxAdapter(child: LabeledDivider()),
                      ),
                      spacer,
                      const _CreateOrganization(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
