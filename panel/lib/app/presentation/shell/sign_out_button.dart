import "package:typewriter_panel/typewriter_panel.dart";

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
          await ref.read(authProvider.notifier).signOut();
        } on Object catch (_) {
          if (!context.mounted) return;
          showErrorSnackBar(context, "Could not sign out. Please try again.");
        }
      },
      child: const Text("Sign out"),
    );
  }
}
