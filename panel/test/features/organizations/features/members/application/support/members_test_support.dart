import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

const testUserId = "user1";
final testOrganizationId = recordId("organization:org1");
final testMemberId = recordId("user:m1");
final testTimestamp = DateTime.utc(2025, 1, 1, 12);

String get memberUpdateSubject =>
    "cloud.to.user.$testUserId.organization.org1.members.update";
String get memberRemoveSubject =>
    "cloud.to.user.$testUserId.organization.org1.members.remove";

OrganizationRole createRole({
  String id = "r1",
  String name = "Role",
  Color color = Colors.grey,
  bool defaultRole = false,
  bool assignable = true,
  bool deletable = false,
}) => OrganizationRole(
  roleId: recordId("organization_role:$id"),
  name: name,
  color: color,
  defaultRole: defaultRole,
  assignable: assignable,
  deletable: deletable,
);

OrganizationMember createMember({
  List<OrganizationRole> roles = const [],
  String name = "Test",
  String email = "test@test.com",
  String avatarUrl = "",
  DateTime? joinedAt,
}) => OrganizationMember(
  userId: testMemberId,
  name: name,
  email: email,
  avatarUrl: avatarUrl,
  roles: roles,
  joinedAt: joinedAt ?? testTimestamp,
);

Future<T> readAsyncData<T>(
  ProviderSubscription<AsyncValue<T>> Function(
    void Function(AsyncValue<T>? previous, AsyncValue<T> next) listener,
  )
  subscribe,
) async {
  final result = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = subscribe((previous, next) {
    if (result.isCompleted) return;
    switch (next) {
      case AsyncData<T>(:final value):
        result.complete(value);
      case AsyncError<T>(:final error, :final stackTrace):
        result.completeError(error, stackTrace);
      default:
    }
  });
  try {
    return await result.future;
  } finally {
    subscription.close();
  }
}

Future<ProviderSubscription<AsyncValue<T>>> retainUntilReady<T>(
  ProviderSubscription<AsyncValue<T>> Function(
    void Function(AsyncValue<T>? previous, AsyncValue<T> next) listener,
  )
  subscribe,
) async {
  final ready = Completer<void>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = subscribe((previous, next) {
    if (ready.isCompleted) return;
    switch (next) {
      case AsyncData<T>():
        ready.complete();
      case AsyncError<T>(:final error, :final stackTrace):
        ready.completeError(error, stackTrace);
      default:
    }
  });
  try {
    await ready.future;
    return subscription;
  } catch (_) {
    subscription.close();
    rethrow;
  }
}

Future<List<OrganizationMember>> readMembers(ProviderContainer container) =>
    readAsyncData(
      (listener) => container.listen(
        organizationMembersProvider,
        listener,
        fireImmediately: true,
      ),
    );

Future<List<OrganizationRole>> readRoles(ProviderContainer container) =>
    readAsyncData(
      (listener) => container.listen(
        organizationRolesProvider,
        listener,
        fireImmediately: true,
      ),
    );

class MockMembersNotifier extends OrganizationMembers {
  MockMembersNotifier(this.members);
  final List<OrganizationMember> members;

  @override
  Stream<List<OrganizationMember>> build() async* {
    yield members;
  }
}

class MockRolesNotifier extends OrganizationRoles {
  MockRolesNotifier(this.roles);
  final List<OrganizationRole> roles;

  @override
  Stream<List<OrganizationRole>> build() async* {
    yield roles;
  }
}
