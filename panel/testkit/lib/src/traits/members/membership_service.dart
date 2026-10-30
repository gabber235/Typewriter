import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/membership_service.dart";

/// The membership service of the open organization holds these [roles],
/// [members], [joinCodes] and [joinRequests] and keeps every change the
/// panel makes to them; a null list never arrives, so its page keeps
/// loading, or fails with [failure] when one is given.
///
/// Unlike [membership], the panel's real projections and commands run over
/// NATS against a [FakeMembershipService], so generating, revoking,
/// approving, declining, changing roles and removing show their outcome.
/// Commands take the world's latency and fail with [commandFailure] when one
/// is given.
Trait membershipService({
  List<skir.OrganizationRole>? roles = const [],
  List<skir.OrganizationMember>? members = const [],
  List<skir.JoinCode>? joinCodes = const [],
  List<skir.OrganizationJoinRequest>? joinRequests = const [],
  Object? failure,
  Object? commandFailure,
}) => _MembershipService(
  () => FakeMembershipService(
    roles: roles,
    members: members,
    joinCodes: joinCodes,
    joinRequests: joinRequests,
    failure: failure,
    commandFailure: commandFailure,
  ),
  (
    members: members?.length ?? 0,
    joinCodes: joinCodes?.length ?? 0,
    joinRequests: joinRequests?.length ?? 0,
  ),
);

/// Builds a fresh service for each world, so a trait list shared between
/// tests never carries one test's changes into the next.
final class _MembershipService extends Trait {
  const _MembershipService(this.create, this.counts);

  final FakeMembershipService Function() create;
  final ({int members, int joinCodes, int joinRequests}) counts;

  @override
  Slot get slot => const Slot("membership");

  @override
  String get description =>
      "membershipService(${counts.members} members, "
      "${counts.joinCodes} join codes, "
      "${counts.joinRequests} join requests)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    final user = world.user;
    final organization = world.organizations.firstOrNull;
    if (user == null || organization == null) return;
    create()
      ..latency = world.latency
      ..serve(
        started.nats,
        user: user.id,
        organization: organization.organizationId,
      );
  });
}
