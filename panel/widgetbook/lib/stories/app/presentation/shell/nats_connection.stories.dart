import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

NatsConnectionState _failed(NatsFailureKind kind) => NatsConnectionState.failed(
  NatsClientException(kind: kind, message: kind.safeDescription),
);

/// What [RequiredNatsConnection] puts in front of the panel for each state
/// of its backend connection; connected and signed out users see the page
/// itself.
@widgetbook.UseCase(name: "Default", type: RequiredNatsConnection)
Widget requiredNatsConnectionUseCase(BuildContext context) {
  final session = [signedIn(ada, organization: acme)];
  return Story(
    context.knobs.traits("Connection", {
      "Connected": session,
      "Signed out": const [],
      "Connecting": [
        ...session,
        natsConnection(const NatsConnectionState.connecting()),
      ],
      "Access denied": [
        ...session,
        natsConnection(_failed(NatsFailureKind.permission)),
      ],
      "Incompatible": [
        ...session,
        natsConnection(_failed(NatsFailureKind.protocol)),
      ],
      "Server unavailable": [
        ...session,
        natsConnection(_failed(NatsFailureKind.unavailable)),
      ],
      "Connection failed": [
        ...session,
        natsConnection(_failed(NatsFailureKind.unknown)),
      ],
      "Closed": [
        ...session,
        natsConnection(const NatsConnectionState.closed()),
      ],
    }),
  );
}
