import "package:typewriter_panel/typewriter_panel.dart";

/// Fills a route or application shell while its initial work is pending.
///
/// The screen communicates progress without owning the operation. Replace it
/// with the resulting route or an [ErrorScreen] when that work completes.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({this.title = "Waiting for connection", super.key});

  /// Heading that identifies the pending operation.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Spacer(),
        Expanded(
          flex: 8,
          child: const RiveAsset(
            asset: "assets/tour.riv",
            stateMachineName: "state_machine",
          ),
        ),
        SizedBox(height: context.spacing.space6),
        Text(
          title,
          style: Theme.of(context).textTheme.displayLarge!
              .copyWith(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        ConnectionScroller(
          style: Theme.of(context).textTheme.bodyMedium!
              .copyWith(fontSize: 20, color: context.colors.contentSecondary),
        ),
        SizedBox(height: context.spacing.space6),
        Spacer(),
      ],
    );
  }
}

/// Shows rotating connection messages beneath a [LoadingScreen] heading.
///
/// The messages are shuffled when this widget is built, so they are
/// illustrative status copy rather than a progress report.
class ConnectionScroller extends StatelessWidget {
  const ConnectionScroller({this.style, super.key});

  /// Text style passed to the rotating status messages.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextScroller(
      texts: [
        "Establishing interstellar connection",
        "Tuning communication frequency",
        "Initiating communication protocol",
        "Negotiating connection parameters",
        "Analyzing network traffic",
        "Establishing telepathic link",
        "Activating quantum communication",
        "Setting up virtual private connection",
        "Checking for network interference",
        "Hacking into the Matrix",
        "Summoning the interdimensional portal",
        "Opening the gateway to the astral plane",
        "Establishing connection to the other side",
        "Connecting to the cosmic mind",
        "Contacting extraterrestrial intelligence",
        "Dialing up the time-space continuum",
        "Downloading thoughts from the future",
        "Establishing link to parallel universe",
        "Establishing link to the universal consciousness",
        "Tuning into the cosmic frequency",
        "Initiating intergalactic communication",
        "Bending the fabric of reality",
        "Syncing with the cosmic clock",
        "Activating the trans-dimensional relay",
        "Establishing telekinetic connection",
        "Channeling the universal energy",
        "Unlocking the secrets of the universe",
        "Contacting the all-seeing eye",
        "Teleporting through time and space",
        "Tuning into the higher dimensions",
        "Connecting to the great beyond",
        "Downloading knowledge from the Akashic Records",
        "Establishing a psychic link",
        "Activating the cosmic gateway",
        "Syncing with the universe's frequency",
        "Tuning into the cosmic vibration",
        "Connecting to the quantum field",
        "Establishing a connection to the divine",
        "Channeling the universal wisdom",
      ]..shuffle(),
      style: style,
    );
  }
}
