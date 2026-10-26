import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The membership side of one organization: its roles, members, join codes
/// and join requests.
///
/// Replaces the four membership projections the panel watches over NATS with
/// the lists given here; a null list never arrives, so its projection stays
/// loading. Holds no service rules.
final class FakeMembership {
  FakeMembership({
    this.roles = const [],
    this.members = const [],
    this.joinCodes = const [],
    this.joinRequests = const [],
  });

  final List<skir.OrganizationRole>? roles;
  final List<skir.OrganizationMember>? members;
  final List<skir.JoinCode>? joinCodes;
  final List<skir.OrganizationJoinRequest>? joinRequests;

  /// Replaces the membership projections.
  List<Override> get overrides => [
    organizationRolesProvider.overrideWith(() => _Roles(roles)),
    organizationMembersProvider.overrideWith(() => _Members(members)),
    organizationJoinCodesProvider.overrideWith(() => _JoinCodes(joinCodes)),
    organizationJoinRequestsProvider.overrideWith(
      () => _JoinRequests(joinRequests),
    ),
  ];
}

final class _Roles extends OrganizationRoles {
  _Roles(this._roles);

  final List<skir.OrganizationRole>? _roles;

  @override
  Stream<List<skir.OrganizationRole>> build() => _arrive(_roles);
}

final class _Members extends OrganizationMembers {
  _Members(this._members);

  final List<skir.OrganizationMember>? _members;

  @override
  Stream<List<skir.OrganizationMember>> build() => _arrive(_members);
}

final class _JoinCodes extends OrganizationJoinCodes {
  _JoinCodes(this._codes);

  final List<skir.JoinCode>? _codes;

  @override
  Stream<List<skir.JoinCode>> build() => _arrive(_codes);
}

final class _JoinRequests extends OrganizationJoinRequests {
  _JoinRequests(this._requests);

  final List<skir.OrganizationJoinRequest>? _requests;

  @override
  Stream<List<skir.OrganizationJoinRequest>> build() => _arrive(_requests);
}

/// [value] once, or nothing ever when [value] is null.
Stream<T> _arrive<T extends Object>(T? value) => value == null
    ? Stream.fromFuture(Completer<T>().future)
    : Stream.value(value);
