import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/nats.dart";

/// The backend reports the open organization's [roles], [members],
/// [joinCodes] and [joinRequests] over NATS.
///
/// Unlike [membership], the panel's real membership projections run against
/// [World.nats]: this trait answers their first snapshot requests at sequence
/// 1, later changes arrive through [MembershipBackendEvents], and commands
/// reach the handlers the test registers. For tests of those projections and
/// commands themselves.
Trait membershipBackend({
  List<skir.OrganizationRole> roles = const [],
  List<skir.OrganizationMember> members = const [],
  List<skir.JoinCode> joinCodes = const [],
  List<skir.OrganizationJoinRequest> joinRequests = const [],
}) => _MembershipBackend(roles, members, joinCodes, joinRequests);

final class _MembershipBackend extends Trait {
  const _MembershipBackend(
    this.roles,
    this.members,
    this.joinCodes,
    this.joinRequests,
  );

  final List<skir.OrganizationRole> roles;
  final List<skir.OrganizationMember> members;
  final List<skir.JoinCode> joinCodes;
  final List<skir.OrganizationJoinRequest> joinRequests;

  @override
  Slot get slot => const Slot("membership");

  @override
  String get description =>
      "membershipBackend(${members.length} members, "
      "${joinCodes.length} join codes, ${joinRequests.length} join requests)";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    final user = world.user;
    final organization = world.organizations.firstOrNull;
    if (user == null || organization == null) return;
    final scope =
        "cloud.to.user.${user.id.transportIdentity}.organization."
        "${organization.organizationId.id.transportIdentity}";
    started.nats
      ..registerHandler(
        "$scope.roles.watch",
        (_) => skir.WatchOrganizationRolesResponse.serializer.toBytes(
          skir.WatchOrganizationRolesResponse.wrapList(roles),
        ),
      )
      ..registerHandler(
        "$scope.members.watch",
        (_) => skir.WatchOrganizationMembersResponse.serializer.toBytes(
          skir.WatchOrganizationMembersResponse.wrapSnapshot(
            skir.OrganizationMembersSnapshot(sequence: 1, values: members),
          ),
        ),
      )
      ..registerHandler(
        "$scope.members.join_codes.watch",
        (_) => skir.WatchOrganizationJoinCodesResponse.serializer.toBytes(
          skir.WatchOrganizationJoinCodesResponse.wrapSnapshot(
            skir.OrganizationJoinCodesSnapshot(sequence: 1, values: joinCodes),
          ),
        ),
      )
      ..registerHandler(
        "$scope.members.join_requests.watch",
        (_) => skir.WatchOrganizationJoinRequestsResponse.serializer.toBytes(
          skir.WatchOrganizationJoinRequestsResponse.wrapSnapshot(
            skir.OrganizationJoinRequestsSnapshot(
              sequence: 1,
              values: joinRequests,
            ),
          ),
        ),
      );
  });
}

/// Membership changes the backend announces to every organization member
/// watching.
extension MembershipBackendEvents on FakeNats {
  String _subject(skir.RecordId organization, String topic) =>
      "cloud.from.organization.${organization.id.transportIdentity}.$topic";

  /// Announces [change] to the members of [organization].
  void announceMembers(
    skir.RecordId organization,
    skir.OrganizationMembersChanged change,
  ) => connection.emitMessageOnSubject(
    _subject(organization, "members.changed"),
    skir.OrganizationMembersChanged.serializer.toBytes(change),
  );

  /// Announces [change] to the join codes of [organization].
  void announceJoinCodes(
    skir.RecordId organization,
    skir.OrganizationJoinCodesChanged change,
  ) => connection.emitMessageOnSubject(
    _subject(organization, "join_codes.changed"),
    skir.OrganizationJoinCodesChanged.serializer.toBytes(change),
  );

  /// Announces [change] to the join requests of [organization].
  void announceJoinRequests(
    skir.RecordId organization,
    skir.OrganizationJoinRequestsChanged change,
  ) => connection.emitMessageOnSubject(
    _subject(organization, "join_requests.changed"),
    skir.OrganizationJoinRequestsChanged.serializer.toBytes(change),
  );
}
