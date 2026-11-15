import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The pending join requests as cards: who asks and until when.
///
/// A click or Space selects a request through the shared selection; the
/// inspector shows its details, the roles to grant, Accept and Decline. The
/// list publishes its rows, so a decline held from the inspector or the
/// context menu sends and refuses on them, and requests that leave the live
/// list leave the selection.
class JoinRequestsList extends HookConsumerWidget {
  const JoinRequestsList({required this.requests, super.key});

  final List<skir.OrganizationJoinRequest> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = useAnimatedRows(
      items: requests,
      identity: (request) => request.requestId,
    );
    ref.useMembershipRows<JoinRequestIdentifier>(
      list: MembershipList.joinRequests,
      rows: rows,
      live: {
        for (final request in requests)
          JoinRequestIdentifier(request.requestId),
      },
    );

    return SelectionCardList<skir.OrganizationJoinRequest>(
      rows: rows,
      selectableOf: (request) => JoinRequestIdentifier(request.requestId),
      labelOf: (request) => request.displayName,
      emptyBuilder: (context) => const EmptyState(
        icon: Fa6Solid.user_plus,
        title: "No join requests",
        description: "When members request to join, they will appear here.",
      ),
      shortcutsOf: (request) => [joinRequestRowDecline(request, rows)],
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

/// The Decline command of [request]'s card: its key. It declines the
/// selection when the selection holds the request, otherwise the request
/// alone.
ActionShortcut joinRequestRowDecline(
  skir.OrganizationJoinRequest request,
  AnimatedRows<skir.OrganizationJoinRequest> rows,
) {
  return joinRequestDecline(
    id: "decline_join_request_${request.requestId}",
    label: "Decline",
    targets: (ref) => {
      for (final id
          in ref
              .selectionOrRow(JoinRequestIdentifier(request.requestId))
              .whereType<JoinRequestIdentifier>())
        id.requestId,
    },
    nameOf: (_, id) => rows[id]?.item.displayName,
    rows: rows,
  );
}

/// What a join request is called on screen.
extension JoinRequestDisplayName on skir.OrganizationJoinRequest {
  String get displayName => userName ?? userEmail ?? "Join request";
}
