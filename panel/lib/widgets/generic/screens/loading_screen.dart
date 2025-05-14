import "package:flutter/material.dart";
import "package:rive/rive.dart";
import "package:typewriter_panel/widgets/generic/components/text_scroller.dart";

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    this.title = "Waiting for connection",
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Expanded(
            flex: 8,
            child: RiveAnimation.asset(
              "assets/tour.riv",
              stateMachines: ["state_machine"],
            ),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          ConnectionScroller(
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          SizedBox(height: 24),
          Spacer(),
        ],
      ),
    );
  }
}

class ConnectionScroller extends StatelessWidget {
  const ConnectionScroller({this.style, super.key});

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
