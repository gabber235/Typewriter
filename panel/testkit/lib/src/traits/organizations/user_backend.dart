import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The backend answers the signed in user's own projections over NATS: the
/// organizations they belong to and the [joinRequests] they wait on.
///
/// Like [backendOverNats], the panel's real projections run against
/// [World.nats] instead of the organization doubles. This trait answers their
/// snapshot requests at sequence 1; requests to create an organization, to
/// join one or to cancel a join request reach the handlers the test
/// registers. For tests of the organization entry page and the user's own
/// membership commands.
Trait userBackend({List<skir.UserJoinRequest> joinRequests = const []}) =>
    _UserBackend(joinRequests);

final class _UserBackend extends Trait {
  const _UserBackend(this.joinRequests);

  final List<skir.UserJoinRequest> joinRequests;

  @override
  Slot get slot => const Slot("backend");

  @override
  String get description => "userBackend(${joinRequests.length} join requests)";

  @override
  void applyTo(WorldBuilder world) {
    world
      ..organizationDoubles = false
      ..onStart((started) {
        final user = world.user;
        if (user == null) return;
        started.nats
          ..registerHandler(
            skir.WatchUserOrganizationsRequest()
                .operation(userId: user.id)
                .subject,
            (_) => skir.WatchUserOrganizationsResponse.serializer.toBytes(
              skir.WatchUserOrganizationsResponse.createSnapshot(
                sequence: 1,
                values: world.organizations,
              ),
            ),
          )
          ..registerHandler(
            skir.WatchUserJoinRequestsRequest()
                .operation(userId: user.id)
                .subject,
            (_) => skir.WatchUserJoinRequestsResponse.serializer.toBytes(
              skir.WatchUserJoinRequestsResponse.createSnapshot(
                sequence: 1,
                values: joinRequests,
              ),
            ),
          );
      });
  }
}

/// The signed in user's request `request_to_join:[organization]` to join the
/// organization `organization:[organization]`, which reads as its id, made at
/// [requestedAt], 2026 by default, and expiring at [expiresAt], 2100 by
/// default.
skir.UserJoinRequest userJoinRequest(
  String organization, {
  DateTime? requestedAt,
  DateTime? expiresAt,
}) => skir.UserJoinRequest(
  requestId: skir.recordId("request_to_join:$organization"),
  organizationId: skir.recordId("organization:$organization"),
  organizationName: organization,
  organizationLogoUrl: "",
  requestedAt: requestedAt ?? DateTime.utc(2026),
  expiresAt: expiresAt ?? DateTime.utc(2100),
);
