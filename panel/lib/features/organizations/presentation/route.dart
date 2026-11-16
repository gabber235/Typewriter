import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "create_organization.dart";
part "join_organization.dart";
part "organizations.dart";

/// Entry route for selecting an organization, joining one, or creating one.
///
/// This page waits on the user scoped organization and join request projections,
/// then composes their ready values into the three entry actions. It does not
/// mutate either projection directly; child forms call their provider owners.
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
          builder: (joinRequests) => FocusTraversalOrder(
            order: const NumericFocusOrder(0),
            child: Pane(
              id: "index",
              primary: true,
              trapFocus: false,
              openFocus: PaneOpenFocus.firstItem,
              child: _IndexPageContent(
                organizations: organizations,
                joinRequests: joinRequests,
              ),
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
            const MutationActivityButton(),
            const FooterSidebarLinks(compact: true, expand: false),
            SizedBox(width: context.spacing.space2),
          ],
        ),
        child: content,
      );
    }

    // Tab goes through the page first, then the activity button, then the
    // footer links.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Stack(
        children: [
          content,
          Positioned(
            top: 8,
            right: 8,
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: MutationActivityButton(),
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 8,
            child: FocusTraversalOrder(
              order: NumericFocusOrder(2),
              child: Pane(
                id: "footer",
                trapFocus: false,
                child: FooterSidebarLinks(expand: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout for the organization entry actions once their projections are ready.
///
/// The list, join form, and create form share one scroll surface so loading and
/// error handling stay at the provider boundary above this widget.
class _IndexPageContent extends StatelessWidget {
  const _IndexPageContent({
    required this.organizations,
    required this.joinRequests,
  });

  final List<skir.Organization> organizations;
  final List<skir.UserJoinRequest> joinRequests;

  Widget spacer(BuildContext context) => SliverGap(context.spacing.space6);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: CustomScrollView(
        primary: true,
        slivers: [
          CenteredSliverMainAxisGroup(
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
                      spacer(context),
                      const SliverToBoxAdapter(
                        child: Enter(
                          token: MotionToken.loadIn,
                          child: LabeledDivider(),
                        ),
                      ),
                      spacer(context),
                    ],
                    _JoinOrganization(joinRequests: joinRequests),
                    spacer(context),
                    const SliverToBoxAdapter(
                      child: Enter(
                        token: MotionToken.loadIn,
                        child: LabeledDivider(),
                      ),
                    ),
                    spacer(context),
                    const _CreateOrganization(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
