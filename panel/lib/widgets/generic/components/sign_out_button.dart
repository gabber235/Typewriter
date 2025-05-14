import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:logto_dart_sdk/logto_client.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/auth.dart";

class SignOutButton extends HookConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final router = ref.read(appRouterProvider);
        try {
          await ref.read(authProvider.notifier).signOut();
        } on LogtoAuthException catch (_) {}
        ref
          ..invalidate(isAuthenticatedProvider)
          ..invalidate(accessTokenProvider);
        await Future.delayed(const Duration(milliseconds: 500));
        await router.reevaluateGuards();
      },
      child: const Text("Sign out"),
    );
  }
}
