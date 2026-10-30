import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";
import "package:typewriter_testkit/src/doubles/members.dart";

/// The open organization has these [roles], [members], [joinCodes] and
/// [joinRequests]; a null list never arrives, so its page keeps loading, or
/// fails with [failure] when one is given.
Trait membership({
  List<skir.OrganizationRole>? roles = const [],
  List<skir.OrganizationMember>? members = const [],
  List<skir.JoinCode>? joinCodes = const [],
  List<skir.OrganizationJoinRequest>? joinRequests = const [],
  Object? failure,
}) => _Membership(
  FakeMembership(
    roles: roles,
    members: members,
    joinCodes: joinCodes,
    joinRequests: joinRequests,
    failure: failure,
  ),
);

final class _Membership extends Trait {
  const _Membership(this.membership);

  final FakeMembership membership;

  @override
  Slot get slot => const Slot("membership");

  @override
  String get description => "membership(...)";

  @override
  void applyTo(WorldBuilder world) =>
      world.overrides.addAll(membership.overrides);
}
