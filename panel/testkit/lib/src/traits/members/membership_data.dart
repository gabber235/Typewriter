import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The role `organization_role:[id]`, named [name] or else [id], drawn in
/// [color].
///
/// An editor may assign it unless [assignable] is false; a [defaultRole] is
/// what a member without other roles gets.
skir.OrganizationRole role(
  String id, {
  String? name,
  Color color = const Color(0xff9e9e9e),
  bool defaultRole = false,
  bool assignable = true,
  bool deletable = false,
}) => skir.OrganizationRole(
  roleId: skir.recordId("organization_role:$id"),
  name: name ?? id,
  color: color.toSkirColor(),
  defaultRole: defaultRole,
  assignable: assignable,
  deletable: deletable,
);

/// The member [name], the user `user:[id]` or else `user:` and [name] in
/// lower case, holding [roles] since [joinedAt], 2026 by default.
skir.OrganizationMember member(
  String name, {
  String? id,
  String? email,
  String? avatarUrl,
  List<skir.OrganizationRole> roles = const [],
  DateTime? joinedAt,
}) => skir.OrganizationMember(
  userId: skir.recordId("user:${id ?? name.toLowerCase()}"),
  name: name,
  email: email,
  avatarUrl: avatarUrl,
  roles: roles,
  joinedAt: joinedAt ?? DateTime.utc(2026),
);

/// The join code `join_code:[id]` made at [createdAt], 2026 by default,
/// expiring at [expiresAt] or never, usable once unless [singleUse] is
/// false, and granting [roles] to whoever joins with it.
skir.JoinCode joinCode(
  String id, {
  DateTime? createdAt,
  DateTime? expiresAt,
  bool singleUse = true,
  List<skir.RecordId> roles = const [],
}) => skir.JoinCode(
  code: skir.recordId("organization_join_code:$id"),
  createdAt: createdAt ?? DateTime.utc(2026),
  expiresAt: expiresAt,
  singleUse: singleUse,
  autoAccept: skir.JoinCode_AutoAccept(roleIds: roles),
);

/// The request `request_to_join:[id]` of the user `user:[id]`, who reads as
/// [name], made at [requestedAt], 2026 by default, and expiring at
/// [expiresAt], 2100 by default.
skir.OrganizationJoinRequest joinRequest(
  String id, {
  String? name,
  String? email,
  String? avatarUrl,
  DateTime? requestedAt,
  DateTime? expiresAt,
}) => skir.OrganizationJoinRequest(
  requestId: skir.recordId("request_to_join:$id"),
  userId: skir.recordId("user:$id"),
  userName: name,
  userEmail: email,
  userAvatarUrl: avatarUrl,
  requestedAt: requestedAt ?? DateTime.utc(2026),
  expiresAt: expiresAt ?? DateTime.utc(2100),
);
