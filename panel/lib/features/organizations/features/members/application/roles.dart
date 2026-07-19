import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/utilities/collection.dart";

part "roles.freezed.dart";
part "roles.g.dart";

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

@riverpod
class OrganizationRoles extends _$OrganizationRoles {
  @override
  Stream<List<OrganizationRole>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
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

    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.roles.watch",
      listenSubject: "cloud.from.organization.${organizationId.id}.roles.watch",
      requestBytes: skir.WatchOrganizationRolesRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationRolesResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationRolesResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationRolesResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationRolesResponse_listWrapper(:final value):
            return value.map(OrganizationRole.fromSkir).toList();
          case skir.WatchOrganizationRolesResponse_addWrapper(:final value):
            return previous.upsertByKey(
              (role) => role.roleId,
              OrganizationRole.fromSkir(value),
            );
          case skir.WatchOrganizationRolesResponse_updateWrapper(:final value):
            return previous.upsertByKey(
              (role) => role.roleId,
              OrganizationRole.fromSkir(value),
            );
          case skir.WatchOrganizationRolesResponse_removeWrapper(:final value):
            return previous?.where((role) => role.roleId != value).toList() ??
                [];
        }
      },
    );
  }
}

/// Provider for the list of members in the current organization.
