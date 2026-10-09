import "package:typewriter_panel/typewriter_panel.dart";

extension VoluntarySignOut on WidgetRef {
  /// Signs out after confirming any protected local work session loss.
  Future<void> signOutVoluntarily(BuildContext context) async {
    final allowed = await read(workSessionLossProvider).allowScopeLoss(
      destination: const LocalWorkScope(userId: null, organizationId: null),
      confirm: () => showWorkSessionLossConfirmation(context),
    );
    if (!allowed || !context.mounted) return;
    await read(authProvider.notifier).signOut();
  }
}

/// Signs out the current user and reports failure without exposing its cause.
///
/// This action is also used by authentication and connection error screens, so
/// it remains usable outside the normal sidebar context.
class SignOutButton extends HookConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await ref.signOutVoluntarily(context);
        } on Object catch (_) {
          if (!context.mounted) return;
          showErrorSnackBar(context, "Could not sign out. Please try again.");
        }
      },
      child: const Text("Sign out"),
    );
  }
}
