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

/// Streams the role catalog for the selected organization.
///
/// The initial list and later add, update, and remove messages are folded into
/// one provider value. Membership editors consume this catalog to render both
/// available choices and the protected roles that must remain visible.
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

    final request = skir.WatchOrganizationRolesRequest();

    yield* ref.watchProjection<
      List<OrganizationRole>,
      skir.WatchOrganizationRolesResponse,
      skir.WatchOrganizationRolesResponse
    >(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.roles.watch",
      eventSubject: "cloud.from.organization.${organizationId.id}.roles.watch",
      requestBytes: skir.WatchOrganizationRolesRequest.serializer.toBytes(
        request,
      ),
      responseSerializer: skir.WatchOrganizationRolesResponse.serializer,
      eventSerializer: skir.WatchOrganizationRolesResponse.serializer,
      snapshot: _roleSnapshot,
      reduce: _applyRoleEvent,
      delivery: const ProjectionDelivery.ephemeral(),
      reconciliation: const ProjectionReconciliation.latest(),
    );
  }
}

List<OrganizationRole> _roleSnapshot(
  skir.WatchOrganizationRolesResponse response,
) => switch (response) {
  skir.WatchOrganizationRolesResponse_listWrapper(:final value) =>
    value.map(OrganizationRole.fromSkir).toList(),
  skir.WatchOrganizationRolesResponse_unknown() =>
    throw ApiException.unknownResponseMessage(),
  skir.WatchOrganizationRolesResponse_internalErrorWrapper() =>
    throw ApiException.internalServerError(),
  _ => throw StateError("Snapshot request returned a role event"),
};

List<OrganizationRole> _applyRoleEvent(
  List<OrganizationRole> current,
  skir.WatchOrganizationRolesResponse event,
) => switch (event) {
  skir.WatchOrganizationRolesResponse_listWrapper(:final value) =>
    value.map(OrganizationRole.fromSkir).toList(),
  skir.WatchOrganizationRolesResponse_addWrapper(:final value) ||
  skir.WatchOrganizationRolesResponse_updateWrapper(
    :final value,
  ) => current.upsertByKey(
    (role) => role.roleId,
    OrganizationRole.fromSkir(value),
  ),
  skir.WatchOrganizationRolesResponse_removeWrapper(:final value) =>
    current.where((role) => role.roleId != value).toList(),
  skir.WatchOrganizationRolesResponse_unknown() =>
    throw ApiException.unknownResponseMessage(),
  skir.WatchOrganizationRolesResponse_internalErrorWrapper() =>
    throw ApiException.internalServerError(),
};

/// Provider for the list of members in the current organization.
