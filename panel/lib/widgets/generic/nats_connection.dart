import "package:dart_nats/dart_nats.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/widgets/generic/error_screen.dart";
import "package:typewriter_panel/widgets/generic/loading_screen.dart";

class RequiredNatsConnection extends HookConsumerWidget {
  const RequiredNatsConnection({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(idTokenProvider).requireValue;
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
        return const ErrorScreen(
          title: "Error",
          message:
              "Could not connect to the server, please check your internet connection.",
        );
    }
  }
}
