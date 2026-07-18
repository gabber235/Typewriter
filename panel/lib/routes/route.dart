import "dart:math";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/hooks/animated_list.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/skir.dart";
import "package:typewriter_panel/utils/snackbar.dart";
import "package:typewriter_panel/utils/snake_case_input_formatter.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/app/components/organization_icon.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/generic/components/countdown_badge.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_message_switcher.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_transition.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_divider.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";
import "package:typewriter_panel/widgets/generic/components/simple_scaffold.dart";
import "package:typewriter_panel/widgets/generic/components/stagger_entrance.dart";

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
          builder: (joinRequests) => _IndexPageContent(
            organizations: organizations,
            joinRequests: joinRequests,
          ),
        ),
      ),
    );

    if (context.isMobile) {
      return SimpleScaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
          actions: const [
            UserMenu(compact: true, expand: false),
            SizedBox(width: 8),
          ],
        ),
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        const Positioned(left: 8, bottom: 8, child: UserMenu(expand: false)),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: StaggerScope(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (organizations.isNotEmpty) ...[
                  _OrganizationsSelector(organizations: organizations),
                  const SizedBox(height: 24),
                  const StaggerEntrance(child: LabeledDivider()),
                  const SizedBox(height: 24),
                ],
                _JoinOrganization(joinRequests: joinRequests),
                const SizedBox(height: 24),
                const StaggerEntrance(child: LabeledDivider()),
                const SizedBox(height: 24),
                const _CreateOrganization(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
