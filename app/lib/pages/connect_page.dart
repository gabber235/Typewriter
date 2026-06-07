import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart" hide Page;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:rive/rive.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/hooks/delayed_execution.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/communicator.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/widgets/components/general/text_scroller.dart";

@RoutePage()
class ConnectPage extends HookConsumerWidget {
  const ConnectPage({
    @QueryParam("host") this.hostname = "",
    @QueryParam() this.port,
    @QueryParam() this.token = "",
    @QueryParam() this.secure = false,
    super.key,
  });

  final String hostname;
  final int? port;
  final String token;
  final bool secure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    // If the hostname is empty, we want to go back to the home page.
    useDelayedExecution(() {
      if (hostname.isEmpty) {
        ref.read(appRouter).replaceAll([const HomeRoute()]);
        return;
      }
    });

    // We want to wait a second before we connect to the server.
    // This is to give the user a chance to read the text.
    useEffect(
      () {
        final timer = Timer(1.seconds, () {
          ref.read(socketProvider.notifier).init(
                hostname,
                port,
                token: token.isEmpty ? null : token,
                secure: secure,
              );
        });
        return timer.cancel;
      },
      [],
    );

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Expanded(
            flex: 8,
            child: RiveAnimation.asset(
              "assets/tour.riv",
              stateMachines: ["state_machine"],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.waitingForConnection,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const ConnectionScroller(
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Spacer(),
        ],
      ),
    );
  }
}

class ConnectionScroller extends HookWidget {
  const ConnectionScroller({this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextScroller(
      texts: [
        l10n.establishingInterstellarConnection,
        l10n.tuningCommunicationFrequency,
        l10n.initiatingCommunicationProtocol,
        l10n.negotiatingConnectionParameters,
        l10n.analyzingNetworkTraffic,
        l10n.establishingTelepathicLink,
        l10n.activatingQuantumCommunication,
        l10n.settingUpVirtualPrivateConnection,
        l10n.checkingForNetworkInterference,
        l10n.hackingIntoTheMatrix,
        l10n.summoningTheInterdimensionalPortal,
        l10n.openingTheGatewayToTheAstralPlane,
        l10n.establishingConnectionToTheOtherSide,
        l10n.connectingToTheCosmicMind,
        l10n.contactingExtraterrestrialIntelligence,
        l10n.dialingUpTheTimeSpaceContinuum,
        l10n.downloadingThoughtsFromTheFuture,
        l10n.establishingLinkToParallelUniverse,
        l10n.establishingLinkToTheUniversalConsciousness,
        l10n.tuningIntoTheCosmicFrequency,
        l10n.initiatingIntergalacticCommunication,
        l10n.bendingTheFabricOfReality,
        l10n.syncingWithTheCosmicClock,
        l10n.activatingTheTransDimensionalRelay,
        l10n.establishingTelekineticConnection,
        l10n.channelingTheUniversalEnergy,
        l10n.unlockingTheSecretsOfTheUniverse,
        l10n.contactingTheAllSeeingEye,
        l10n.teleportingThroughTimeAndSpace,
        l10n.tuningIntoTheHigherDimensions,
        l10n.connectingToTheGreatBeyond,
        l10n.downloadingKnowledgeFromTheAkashicRecords,
        l10n.establishingAPsychicLink,
        l10n.activatingTheCosmicGateway,
        l10n.syncingWithTheUniverseFrequency,
        l10n.tuningIntoTheCosmicVibration,
        l10n.connectingToTheQuantumField,
        l10n.establishingAConnectionToTheDivine,
        l10n.channelingTheUniversalWisdom,
      ]..shuffle(),
      style: style,
    );
  }
}
