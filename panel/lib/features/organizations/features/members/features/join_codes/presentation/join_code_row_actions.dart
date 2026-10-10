import "package:typewriter_panel/typewriter_panel.dart";

/// Desktop row control for revoking one invitation code.
/// It hides itself while its asynchronous revoke operation is in flight; the
/// provider performs optimistic removal and restores state on failure.
class JoinCodeRowActions extends HookConsumerWidget {
  const JoinCodeRowActions({required this.code, super.key});

  final OrganizationJoinCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isRevoking = useState(false);

    if (isRevoking.value) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.space2),
      child: IconButton(
        icon: Icon(Icons.link_off, size: 20, color: theme.colorScheme.error),
        onPressed: () => _confirmRevokeCode(context, ref, isRevoking),
        tooltip: "Revoke join code",
      ),
    );
  }

  Future<void> _confirmRevokeCode(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isRevoking,
  ) async {
    await showConfirmationDialogue(
      context: context,
      title: "Revoke this join code?",
      content: "Are you sure you want to revoke this join code? It will no longer work for new members.",
      confirmText: "Revoke",
      confirmIcon: Fa6Solid.link_slash,
      onConfirm: () async {
        isRevoking.value = true;
        await ref.executeMembership(
          ref.membershipCommands.revoke(code.code),
          (response) => response.requireAccepted(),
        );
      },
    );
  }
}
