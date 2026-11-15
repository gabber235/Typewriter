import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The pending join requests as cards: who asks and until when.
///
/// A click or Space selects a request through the shared selection; the
/// inspector shows its details, the roles to grant, Accept and Decline. The
/// list gives its rows to the page's selection surface, so a decline held
/// from the inspector or the context menu sends and refuses on them. Cards
/// change nothing themselves.
class JoinRequestsList extends HookConsumerWidget {
  const JoinRequestsList({required this.requests, super.key});

  final List<skir.OrganizationJoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = useAnimatedRows(
      items: requests,
      identity: (request) => request.requestId,
    );
    useSelectionSurfaceRows(rows);

    return SelectionCardList<skir.OrganizationJoinRequest>(
      rows: rows,
      selectableOf: (request) => JoinRequestIdentifier(request.requestId),
      labelOf: (request) => request.displayName,
      emptyBuilder: (context) => const EmptyState(
        icon: Fa6Solid.user_plus,
        title: "No join requests",
        description: "When members request to join, they will appear here.",
      ),
      contentBuilder: (context, request) => Row(
        spacing: context.spacing.space3,
        children: [
          MemberAvatar(
            avatarUrl:
                request.userAvatarUrl?.nullIfEmpty ??
                "$userIconUrl&seed=${request.userId}",
            radius: 20,
          ),
          Expanded(
            child: PersonSummary(
              name: request.userName,
              email: request.userEmail,
            ),
          ),
          CountdownBadge(endDate: request.expiresAt),
        ],
      ),
    );
  }
}

/// What a join request is called on screen.
extension JoinRequestDisplayName on skir.OrganizationJoinRequest {
  String get displayName => userName ?? userEmail ?? "Join request";
}
