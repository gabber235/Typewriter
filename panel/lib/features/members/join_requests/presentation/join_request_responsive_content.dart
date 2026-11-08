import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Mobile and tablet body for one join request card.
///
/// This widget adapts layout only. Selection, expiry cleanup, decline
/// confirmation, and expansion remain callbacks owned by the card and list so
/// responsive rendering cannot create a second state owner.
class JoinRequestResponsiveContent extends StatelessWidget {
  const JoinRequestResponsiveContent({
    required this.request,
    required this.isSelected,
    required this.isExpanded,
    required this.onExpired,
    required this.onDecline,
    required this.onToggle,
    super.key,
  });
  final skir.OrganizationJoinRequest request;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onExpired;
  final VoidCallback onDecline;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SelectableAvatar(
              avatarUrl:
                  request.userAvatarUrl?.nullIfEmpty ??
                  "$userIconUrl&seed=${request.userId}",
              isSelected: isSelected,
              radius: 20,
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: PersonSummary(
                name: request.userName,
                email: request.userEmail,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space3),
        Row(
          children: [
            CountdownBadge(endDate: request.expiresAt, onExpired: onExpired),
          ],
        ),
        SizedBox(height: context.spacing.space3),
        Row(
          children: [
            Expanded(
              child: Button(
                face: ButtonFace.outlined,
                label: "Decline",
                color: context.colors.dangerText,
                onPressed: onDecline,
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: Button(
                face: ButtonFace.filled,
                label: isExpanded ? "Cancel" : "Accept",
                onPressed: onToggle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
