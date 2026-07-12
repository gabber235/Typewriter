import "dart:async";

import "package:faker/faker.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_panel/utils/skir.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/secret_field.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

OrganizationData generateRandomOrganization() {
  return OrganizationData(
    organizationId: recordId("organization:${faker.guid.guid()}"),
    name: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    logoUrl: generateOrganizationIconUrl(faker.guid.guid()),
  );
}

class OrganizationsMock extends Organizations {
  OrganizationsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<OrganizationData>> build() async* {
    yield await displayState.generate(generateRandomOrganization);
  }

  @override
  Future<skir.RecordId> createOrganization({
    required String name,
    required String logoUrl,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    return recordId("organization:${faker.guid.guid()}");
  }
}

class OrganizationProviderMock extends Organization {
  OrganizationProviderMock();

  @override
  Future<OrganizationData?> build() async {
    final organizations = await ref.watch(organizationsProvider.future);
    return organizations.firstOrNull;
  }

  @override
  Future<SecretFieldRevealed> generateJoinCode({
    JoinCodeOptions options = const JoinCodeOptions(),
  }) async {
    await Future<void>.delayed(2500.ms);
    final expiresAt = switch (options.expiration) {
      JoinCodeExpirationNever() => null,
      JoinCodeExpirationDuration(:final duration) => DateTime.now().add(
        duration,
      ),
    };
    return SecretFieldRevealed(
      value: "Roft9n2cgVEypNBanD23",
      expiresAt: expiresAt,
    );
  }
}

List<Override> organizationsProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [
  organizationsProvider.overrideWith(
    () => OrganizationsMock(displayState: state),
  ),
];

List<Override> organizationProviderOverrides() => [
  organizationProvider.overrideWith(() => OrganizationProviderMock()),
  organizationIdProvider.overrideWith(
    (ref) => ref
        .watch(organizationProvider)
        .whenData((value) => value?.organizationId)
        .value,
  ),
];

// ============================================================================
// Member Role Mocks
// ============================================================================

const _roleColors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
];

const _roleNames = [
  "Founder",
  "Admin",
  "Contributor",
  "Editor",
  "Developer",
  "Moderator",
  "Viewer",
  "Guest",
];

List<OrganizationRole> presetRoles() {
  final presetRoles = List.generate(_roleNames.length, (i) {
    final isFirst = i == 0;
    final isLast = i == _roleNames.length - 1;
    return OrganizationRole(
      roleId: recordId("organization_role:${faker.guid.guid()}"),
      name: _roleNames[i],
      color: _roleColors[i],
      deletable: !isFirst && !isLast,
      assignable: !isFirst,
      defaultRole: isLast,
    );
  });

  return presetRoles;
}

// ============================================================================
// Organization Member Mocks
// ============================================================================

OrganizationMember generateRandomMember({
  List<OrganizationRole>? availableRoles,
}) {
  final roles = availableRoles != null
      ? (availableRoles.toList()..shuffle())
            .take(faker.randomGenerator.integer(3, min: 1))
            .toList()
      : presetRoles();

  return OrganizationMember(
    userId: recordId("user:${faker.guid.guid()}"),
    name: faker.person.name(),
    email: faker.internet.email(),
    avatarUrl:
        "https://api.dicebear.com/9.x/avataaars/webp?seed=${faker.guid.guid()}",
    roles: roles,
    joinedAt: faker.date.dateTime(minYear: 2020, maxYear: 2024),
  );
}

class OrganizationRolesMock extends OrganizationRoles {
  OrganizationRolesMock({required this.roles});

  final List<OrganizationRole> roles;

  @override
  Stream<List<OrganizationRole>> build() async* {
    yield roles;
  }
}

class OrganizationMembersMock extends OrganizationMembers {
  OrganizationMembersMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<OrganizationMember>> build() async* {
    final availableRoles = await ref.watch(organizationRolesProvider.future);
    yield await displayState.generate(
      () => generateRandomMember(availableRoles: availableRoles),
    );
  }

  @override
  Future<void> updateMemberRoles(
    skir.RecordId memberId,
    List<OrganizationRole> requestedRoles,
  ) async {
    final members = await future;

    state = AsyncData(
      members.map((member) {
        if (member.userId == memberId) {
          return member.copyWith(roles: requestedRoles);
        }
        return member;
      }).toList(),
    );
  }

  @override
  Future<void> removeMember(skir.RecordId memberId) async {
    final members = await future;

    state = AsyncData(members.where((m) => m.userId != memberId).toList());
  }
}

// ============================================================================
// Join Request Mocks
// ============================================================================

OrganizationJoinRequest generateRandomJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 5)),
  );
  return OrganizationJoinRequest(
    requestId: recordId("request_to_join:${faker.guid.guid()}"),
    userId: recordId("user:${faker.guid.guid()}"),
    userName: faker.person.name(),
    userEmail: faker.internet.email(),
    userAvatarUrl:
        "https://api.dicebear.com/9.x/avataaars/webp?seed=${faker.guid.guid()}",
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class OrganizationJoinRequestsMock extends OrganizationJoinRequests {
  OrganizationJoinRequestsMock({required this.displayState, this.onApprove});

  final DisplayState displayState;
  final void Function(
    OrganizationJoinRequest request,
    List<OrganizationRole> roles,
  )?
  onApprove;

  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    yield await displayState.generate(generateRandomJoinRequest);
  }

  @override
  Future<void> approveRequest(
    skir.RecordId requestId,
    List<OrganizationRole> roles,
  ) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final request = requests.firstWhere((r) => r.requestId == requestId);
    final updated = requests.where((r) => r.requestId != requestId).toList();
    state = AsyncData(updated);

    onApprove?.call(request, roles);
  }

  @override
  Future<void> declineRequest(skir.RecordId requestId) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final updated = requests.where((r) => r.requestId != requestId).toList();
    state = AsyncData(updated);
  }
}

// ============================================================================
// Override Helpers
// ============================================================================

List<Override> organizationMembersProviderOverrides({
  DisplayState state = DisplayState.fewItems,
}) {
  final roles = presetRoles();
  return [
    organizationRolesProvider.overrideWith(
      () => OrganizationRolesMock(roles: roles),
    ),
    organizationMembersProvider.overrideWith(
      () => OrganizationMembersMock(displayState: state),
    ),
  ];
}

List<Override> organizationJoinRequestsProviderOverrides({
  DisplayState state = DisplayState.fewItems,
}) => [
  organizationJoinRequestsProvider.overrideWith(
    () => OrganizationJoinRequestsMock(displayState: state),
  ),
];

// ============================================================================
// Join Code Mocks
// ============================================================================

OrganizationJoinCode generateRandomJoinCode({
  List<OrganizationRole>? availableRoles,
}) {
  final random = faker.randomGenerator;

  // Randomly decide if this code expires or never expires (30% chance never expires)
  final neverExpires = random.boolean() && random.boolean();
  final expiresAt = neverExpires
      ? null
      : DateTime.now().add(Duration(hours: random.integer(168, min: 1)));

  // Randomly decide if single-use (70% chance)
  final singleUse = random.boolean() || random.boolean();

  // Randomly decide if auto-accept (40% chance)
  final hasAutoAccept = random.boolean() && random.boolean();
  final autoAccept = hasAutoAccept && availableRoles != null
      ? JoinCodeAutoAccept(
          roleIds: (availableRoles.toList()..shuffle())
              .take(random.integer(3, min: 1))
              .map((r) => r.roleId)
              .toList(),
        )
      : JoinCodeAutoAccept();

  return OrganizationJoinCode(
    code: recordId("organization_join_codes:${generateCode(20)}"),
    createdAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
    singleUse: singleUse,
    autoAccept: autoAccept,
  );
}

class OrganizationJoinCodesMock extends OrganizationJoinCodes {
  OrganizationJoinCodesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    final availableRoles = await ref.watch(organizationRolesProvider.future);
    yield await displayState.generate(
      () => generateRandomJoinCode(availableRoles: availableRoles),
    );
  }

  @override
  Future<void> revokeCode(skir.RecordId codeId) async {
    await Future.delayed(300.ms);
    final codes = await future;

    final updated = codes.where((c) => c.code != codeId).toList();
    state = AsyncData(updated);
  }
}

List<Override> organizationJoinCodesProviderOverrides({
  DisplayState state = DisplayState.fewItems,
}) => [
  organizationJoinCodesProvider.overrideWith(
    () => OrganizationJoinCodesMock(displayState: state),
  ),
];

// ============================================================================
// User Join Request Mocks (for the user's own pending requests)
// ============================================================================

UserJoinRequest generateRandomUserJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 1)),
  );
  return UserJoinRequest(
    requestId: recordId("request_to_join:${faker.guid.guid()}"),
    organizationId: recordId("organization:${faker.guid.guid()}"),
    organizationName: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    organizationLogoUrl: generateOrganizationIconUrl(faker.guid.guid()),
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class UserJoinRequestsMock extends UserJoinRequests {
  UserJoinRequestsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<UserJoinRequest>> build() async* {
    yield await displayState.generate(generateRandomUserJoinRequest);
  }

  @override
  Future<void> requestToJoin(String urlOrCode) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    final newRequest = generateRandomUserJoinRequest();
    state = AsyncData([newRequest, ...currentRequests]);
  }

  @override
  Future<void> cancelRequest(skir.RecordId requestId) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    state = AsyncData(
      currentRequests.where((r) => r.requestId != requestId).toList(),
    );
  }
}

List<Override> userJoinRequestsProviderOverrides({
  DisplayState state = DisplayState.noItems,
}) => [
  userJoinRequestsProvider.overrideWith(
    () => UserJoinRequestsMock(displayState: state),
  ),
];
