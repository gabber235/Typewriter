import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/widgets/generic/components/loading_button.dart";

@RoutePage()
class AuthPage extends HookConsumerWidget {
  const AuthPage({required this.onResult, super.key});

  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isAuthenticated) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Expanded(
            flex: 2,
            child: RiveAnimation.asset(
              "assets/game_character.riv",
              stateMachines: ["State Machine"],
            ),
          ),
          Text(
            "Your journey starts here",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          LoadingButton(
            child: const Text("Sign in"),
            onPressed: () async {
              await ref.read(authProvider.notifier).signIn();
              if (!context.mounted) return;
              final isAuthenticated =
                  await ref.read(isAuthenticatedProvider.future);
              onResult(isAuthenticated);
            },
          ),
          Spacer(),
        ],
      ),
    );
  }
}
