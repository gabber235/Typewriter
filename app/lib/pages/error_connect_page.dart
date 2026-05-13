import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart" hide FilledButton;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:typewriter/hooks/delayed_execution.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/widgets/components/general/copyable_text.dart";
import "package:typewriter/utils/extensions.dart";

@RoutePage()
class ErrorConnectPage extends HookConsumerWidget {
  const ErrorConnectPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    useDelayedExecution(() {
      // Make sure the socket gets cleaned up
      ref.invalidate(socketProvider);
    });

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Expanded(
            flex: 6,
            child: MouseRegion(
              cursor: SystemMouseCursors.zoomIn,
              child: RiveAnimation.asset(
                "assets/robot_island.riv",
                stateMachines: ["Motion"],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.errorConnectTitle,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            l10n.errorConnectSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const CopyableText(text: "/typewriter connect"),
          const SizedBox(height: 24),
          const Spacer(),
        ],
      ),
    );
  }
}
