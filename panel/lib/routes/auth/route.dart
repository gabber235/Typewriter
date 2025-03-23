import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/hooks/delayed_execution.dart";
import "package:typewriter_panel/logic/auth.dart";

@RoutePage()
class AuthPage extends HookConsumerWidget {
  const AuthPage({required this.onResult, super.key});

  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isAuthenticated) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useDelayedExecution(() async {
      await ref.read(authProvider.notifier).signIn();
      if (!context.mounted) return;
      final isAuthenticated = await ref.read(isAuthenticatedProvider.future);
      onResult(isAuthenticated);
    });
    return Center(child: CircularProgressIndicator());
  }
}
