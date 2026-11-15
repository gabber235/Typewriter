import "package:typewriter_panel/typewriter_panel.dart";

/// What the inspector shows for the selected join [requests]: who asks and
/// until when, for one request, then the roles every one of them is
/// granted once accepted.
///
/// Accept is offered once every selected request has a role to grant; it
/// accepts each with its own roles.
class JoinRequestInspection extends ConsumerWidget {
  const JoinRequestInspection({required this.requests, super.key});

  final List<JoinRequestSelectable> requests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final single = requests.length == 1 ? requests.single.request : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: [
        if (single != null) ...[
          Row(
            spacing: context.spacing.space3,
            children: [
              SelectableAvatar(
                avatarUrl:
                    single.userAvatarUrl?.nullIfEmpty ??
                    "$userIconUrl&seed=${single.userId}",
                isSelected: false,
                radius: 24,
              ),
              Expanded(
                child: PersonSummary(
                  name: single.userName,
                  email: single.userEmail,
                ),
              ),
            ],
          ),
          InspectionDetail(
            label: "Expires",
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: CountdownBadge(endDate: single.expiresAt),
            ),
          ),
        ],
        const SectionTitle(title: "Roles to grant"),
        RoleChecks(
          assignableOnly: true,
          held: [for (final request in requests) request.grant],
          onChanged: (next, _) =>
              ref.read(joinRequestGrantsProvider.notifier).grant({
                for (final (index, request) in requests.indexed)
                  request.request.requestId: next[index],
              }),
        ),
      ],
    );
  }
}
