import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "membership_search.freezed.dart";
part "membership_search.g.dart";

const memberSearchResultType = SearchResultType(
  id: "member",
  rowRendererId: "member",
  label: "Member",
);

const joinCodeSearchResultType = SearchResultType(
  id: "join_code",
  rowRendererId: "join_code",
  label: "Join code",
);

const joinRequestSearchResultType = SearchResultType(
  id: "join_request",
  rowRendererId: "join_request",
  label: "Join request",
);

/// One active join code as search shows it: the code and the roles it grants
/// straight away, none when a newcomer waits for approval.
@freezed
abstract class JoinCodeSearchItem with _$JoinCodeSearchItem {
  const factory JoinCodeSearchItem({
    required skir.JoinCode code,
    required List<skir.OrganizationRole> roles,
  }) = _JoinCodeSearchItem;
}

/// The selected organization's members, for search.
///
/// Gives none while the list still belongs to the organization shown before,
/// so search never lists another organization's members.
@riverpod
AsyncValue<List<skir.OrganizationMember>> memberSearchItems(Ref ref) {
  final members = ref.watch(organizationMembersProvider);
  if (members.isReloading) return const AsyncLoading();
  return members;
}

/// The selected organization's active join codes with the roles each grants,
/// for search; none while the codes still belong to the organization shown
/// before.
@riverpod
AsyncValue<List<JoinCodeSearchItem>> joinCodeSearchItems(Ref ref) {
  if (ref.watch(
    organizationJoinCodesProvider.select((codes) => codes.isReloading),
  )) {
    return const AsyncLoading();
  }
  final codes = ref.watch(visibleOrganizationJoinCodesProvider);
  if (codes.mapUnready<List<JoinCodeSearchItem>>() case final unready?) {
    return unready;
  }
  final roles = ref.watch(organizationRolesProvider).value ?? const [];
  return AsyncData([
    for (final code in codes.requireValue)
      JoinCodeSearchItem(
        code: code,
        roles: [
          for (final role in roles)
            if (code.autoAccept.roleIds.contains(role.roleId)) role,
        ],
      ),
  ]);
}

/// The selected organization's pending join requests, for search; none
/// while the requests still belong to the organization shown before.
@riverpod
AsyncValue<List<skir.OrganizationJoinRequest>> joinRequestSearchItems(Ref ref) {
  if (ref.watch(
    organizationJoinRequestsProvider.select((requests) => requests.isReloading),
  )) {
    return const AsyncLoading();
  }
  return ref.watch(visibleOrganizationJoinRequestsProvider);
}

extension MemberSearchText on skir.OrganizationMember {
  /// The member's name, else their email.
  String get searchTitle => name ?? email ?? "Member";

  /// The roles the member holds, by name.
  String get rolesLine =>
      roles.isEmpty ? "No roles" : roles.map((role) => role.name).join(", ");
}

extension JoinCodeSearchText on JoinCodeSearchItem {
  /// The roles the code grants and how often it works, such as
  /// `Builder, Multi-use`.
  String get detail => [
    if (roles.isEmpty) "Needs approval" else ...roles.map((role) => role.name),
    if (code.singleUse) "Single-use" else "Multi-use",
  ].join(", ");
}

extension JoinRequestSearchText on skir.OrganizationJoinRequest {
  /// The name of who asks, else their email.
  String get searchTitle => userName ?? userEmail ?? "Join request";
}
