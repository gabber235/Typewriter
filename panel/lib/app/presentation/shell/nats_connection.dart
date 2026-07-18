import "package:dart_nats/dart_nats.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shell/sign_out_button.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
import "package:typewriter_panel/shared/ui/screens/loading_screen.dart";

class RequiredNatsConnection extends HookConsumerWidget {
  const RequiredNatsConnection({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(accessTokenProvider).value;
    // If the user is not authenticated, we want to allow the user to sign in.
    if (token == null) {
      return child;
    }

    final status = ref.watch(natsStatusProvider);
    switch (status) {
      case Status.connecting:
      case Status.tlsHandshake:
      case Status.infoHandshake:
      case Status.reconnecting:
        return const LoadingScreen();
      case Status.connected:
        return child;
      case Status.closed:
      case Status.disconnected:
        return ErrorScreen(
          title: "Error",
          message:
              "Could not connect to the server, please check your internet connection.\nSometimes sign out and sign in again helps.",
          child: SignOutButton(),
        );
    }
  }
}
