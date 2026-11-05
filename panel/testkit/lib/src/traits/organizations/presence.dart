import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// Presence in an organization as it travels over NATS: what the panel
/// publishes about its user and what other members announce.
extension OrganizationPresenceOverNats on FakeNats {
  /// The presence events the panel published for [user] in [organization]
  /// over its last connection, oldest first.
  List<skir.PresenceEvent> presencePublished(
    String user,
    skir.RecordId organization,
  ) {
    final subject = OrganizationPresenceRouteEvent.subject(
      userId: user,
      organizationId: organization,
    );
    return [
      for (final publication in connection.publications)
        if (publication.subject == subject)
          OrganizationPresenceRouteEvent.serializer.fromBytes(
            publication.payload,
          ),
    ];
  }

  /// [user] announces [event] to everyone in [organization].
  void announcePresence(
    String user,
    skir.PresenceEvent event, {
    required skir.RecordId organization,
  }) => connection.emitMessageOnSubject(
    OrganizationPresenceRouteEvent.subject(
      userId: user,
      organizationId: organization,
    ),
    OrganizationPresenceRouteEvent.serializer.toBytes(event),
  );
}

/// The presence the panel shows of other members.
extension OrganizationPresenceOfWorld on World {
  /// Where the other sessions in the open organization are, by user.
  Map<String, skir.PresenceLocation> get othersPresent => {
    for (final session
        in container.read(organizationPresenceProvider).value?.values ??
            const <ActivePanelPresence>[])
      session.userId: session.presence.location,
  };
}
