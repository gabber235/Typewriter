import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The membership side of one organization: its roles, members, join codes
/// and join requests.
///
/// Replaces the four membership projections the panel watches over NATS with
/// the lists given here; a null list never arrives, so its projection stays
/// loading, or fails with [failure] when one is given. Holds no service rules.
final class FakeMembership {
  FakeMembership({
    this.roles = const [],
    this.members = const [],
    this.joinCodes = const [],
    this.joinRequests = const [],
    this.failure,
  });

  final List<skir.OrganizationRole>? roles;
  final List<skir.OrganizationMember>? members;
  final List<skir.JoinCode>? joinCodes;
  final List<skir.OrganizationJoinRequest>? joinRequests;

  /// What every list left null fails with; null keeps them loading.
  final Object? failure;

  /// Replaces the membership projections.
  List<Override> get overrides => [
    organizationRolesProvider.overrideWith(() => _Roles(roles, failure)),
    organizationMembersProvider.overrideWith(() => _Members(members, failure)),
    organizationJoinCodesProvider.overrideWith(
      () => _JoinCodes(joinCodes, failure),
    ),
    organizationJoinRequestsProvider.overrideWith(
      () => _JoinRequests(joinRequests, failure),
    ),
  ];
}

final class _Roles extends OrganizationRoles {
  _Roles(this._roles, this._failure);

  final List<skir.OrganizationRole>? _roles;
  final Object? _failure;

  @override
  Stream<List<skir.OrganizationRole>> build() => _arrive(_roles, _failure);
}

final class _Members extends OrganizationMembers {
  _Members(this._members, this._failure);

  final List<skir.OrganizationMember>? _members;
  final Object? _failure;

  @override
  Stream<List<skir.OrganizationMember>> build() => _arrive(_members, _failure);
}

final class _JoinCodes extends OrganizationJoinCodes {
  _JoinCodes(this._codes, this._failure);

  final List<skir.JoinCode>? _codes;
  final Object? _failure;

  @override
  Stream<List<skir.JoinCode>> build() => _arrive(_codes, _failure);
}

final class _JoinRequests extends OrganizationJoinRequests {
  _JoinRequests(this._requests, this._failure);

  final List<skir.OrganizationJoinRequest>? _requests;
  final Object? _failure;

  @override
  Stream<List<skir.OrganizationJoinRequest>> build() =>
      _arrive(_requests, _failure);
}

/// [value] once; without one, [failure] or nothing ever.
Stream<T> _arrive<T extends Object>(T? value, Object? failure) =>
    switch ((value, failure)) {
      (final T value, _) => Stream.value(value),
      (null, final Object failure) => Stream.error(failure),
      (null, null) => Stream.fromFuture(Completer<T>().future),
    };
