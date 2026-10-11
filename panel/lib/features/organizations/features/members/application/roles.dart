import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "roles.freezed.dart";
part "roles.g.dart";

/// Role metadata used by membership editors.
///
/// [assignable] is the client visible permission boundary for ordinary role
/// changes. Roles that are not assignable remain visible because they are part
/// of a member's authoritative projection, but the controls cannot edit them.
@freezed
abstract class OrganizationRole with _$OrganizationRole {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory OrganizationRole({
    required skir.RecordId roleId,
    required String name,
    required Color color,
    @Default(false) bool defaultRole,
    @Default(false) bool assignable,
    @Default(false) bool deletable,
  }) = _OrganizationRole;

  const OrganizationRole._();

  factory OrganizationRole.fromSkir(skir.OrganizationRole role) =>
      OrganizationRole(
        roleId: role.roleId,
        name: role.name,
        color: role.color.toFlutterColor(),
        defaultRole: role.defaultRole,
        assignable: role.assignable,
        deletable: role.deletable,
      );

  skir.OrganizationRole toSkir() => skir.OrganizationRole(
    roleId: roleId,
    name: name,
    color: color.toSkirColor(),
    defaultRole: defaultRole,
    assignable: assignable,
    deletable: deletable,
  );
}

/// Loads the role catalog for the selected organization.
///
/// Membership editors consume this catalog to render available choices and
/// the protected roles that must remain visible. Invalidating this provider
/// reloads the authoritative snapshot.
@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Stream<List<OrganizationRole>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (!ref.mounted) return;

    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final response = await ref.requestSkir(
      skir.WatchOrganizationRolesRequest().operation(
        userId: userId,
        organizationId: organizationId,
      ),
    );
    if (!ref.mounted) return;
    yield response.readRoleSnapshot();
  }
}

extension OrganizationRoleSnapshot on skir.WatchOrganizationRolesResponse {
  List<OrganizationRole> readRoleSnapshot() => switch (this) {
    skir.WatchOrganizationRolesResponse_listWrapper(:final value) =>
      value.map(OrganizationRole.fromSkir).toList(),
    skir.WatchOrganizationRolesResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
    skir.WatchOrganizationRolesResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationRolesResponse_addWrapper() ||
    skir.WatchOrganizationRolesResponse_updateWrapper() ||
    skir.WatchOrganizationRolesResponse_removeWrapper() => throw StateError(
      "Snapshot request returned a role change",
    ),
  };
}

/// Provider for the list of members in the current organization.
