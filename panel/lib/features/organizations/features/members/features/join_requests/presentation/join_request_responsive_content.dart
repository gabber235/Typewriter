import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
  final OrganizationJoinRequest request;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onExpired;
  final VoidCallback onDecline;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  if (request.userName != null)
                    Text(
                      request.userName!,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontVariations: [.weight(600)],
                        fontSize: 15,
                      ),
                    ),
                  if (request.userEmail != null)
                    Text(
                      request.userEmail!,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
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
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Text("Decline"),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: FilledButton(
                onPressed: onToggle,
                child: Text(isExpanded ? "Cancel" : "Accept"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
