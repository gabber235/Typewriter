import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
