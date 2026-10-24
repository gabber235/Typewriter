import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "roles.g.dart";

/// Role presentation used by membership editors.
///
/// [skir.OrganizationRole.assignable] advertises whether ordinary role changes
/// may select this role; the server still authorizes commands. Protected roles
/// remain visible as part of a member's authoritative projection, but these
/// controls cannot edit them.
extension OrganizationRoleAppearance on skir.OrganizationRole {
  /// The role color as a Flutter value.
  Color get displayColor => color.toFlutterColor();
}

/// Loads the role catalog for the selected organization.
///
/// Membership editors consume this catalog to render available choices and
/// the protected roles that must remain visible. Invalidating this provider
/// reloads the authoritative snapshot.
@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Stream<List<skir.OrganizationRole>> build() async* {
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
  List<skir.OrganizationRole> readRoleSnapshot() => switch (this) {
    skir.WatchOrganizationRolesResponse_listWrapper(:final value) =>
      value.toList(),
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
