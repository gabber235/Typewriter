import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop row action that confirms and delegates membership removal.
///
/// The local flag removes the action after confirmation begins, preventing
/// repeated clicks while the provider submits the operation. Server failures
/// remain owned by the shared error and submission handling.
class MemberRowActions extends HookConsumerWidget {
  const MemberRowActions({required this.member, super.key});

  final OrganizationMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRemoving = useState(false);

    if (isRemoving.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: IconButton(
        icon: Icon(
          Icons.person_remove_outlined,
          size: 20,
          color: theme.colorScheme.error,
        ),
        onPressed: () => _confirmRemoveMember(context, ref, isRemoving),
        tooltip: "Remove member",
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRemoving,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Remove ${member.name}?",
      content:
          "Are you sure you want to remove this member from the organization?",
      confirmText: "Remove",
      confirmIcon: Fa6Solid.user_minus,
      onConfirm: () async {
        isRemoving.value = true;
        await ref.executeMembership(
          ref.membershipCommands.remove(member.userId),
          (response) => response.requireAccepted(),
        );
      },
    );
  }
}
