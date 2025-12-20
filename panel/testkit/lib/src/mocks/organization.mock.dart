import "dart:async";

import "package:faker/faker.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/organization.pb.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/generic/components/secret_field.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

OrganizationData generateRandomOrganization() {
  return OrganizationData()
    ..id = faker.guid.guid()
    ..name = faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase()
    ..iconUrl = generateOrganizationIconUrl(faker.guid.guid());
}

class OrganizationsMock extends Organizations {
  OrganizationsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<OrganizationData>> build() async {
    return displayState.generate(generateRandomOrganization);
  }

  @override
  Future<String?> createOrganization({
    required String name,
    required String iconUrl,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    return null;
  }
}

class OrganizationProviderMock extends Organization {
  OrganizationProviderMock({required this.organization});

  final OrganizationData organization;

  @override
  Future<OrganizationData?> build() async {
    return organization;
  }

  @override
  Future<SecretFieldRevealed> generateInviteLink() async {
    await Future<void>.delayed(2500.ms);
    return SecretFieldRevealed(
      value: "abc123xyz789",
      expiresAt: DateTime.now().add(5.minutes),
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

List<Override> organizationProviderOverrides({
  OrganizationData? organization,
}) => [
  organizationProvider.overrideWith(
    () => OrganizationProviderMock(
      organization: organization ?? generateRandomOrganization(),
    ),
  ),
  organizationIdProvider.overrideWith(
    (ref) =>
        ref.watch(organizationProvider).whenData((value) => value?.id).value,
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

List<MemberRole> presetRoles() {
  final presetRoles = List.generate(_roleNames.length, (i) {
    final isFirst = i == 0;
    final isLast = i == _roleNames.length - 1;
    return MemberRole(
      id: faker.guid.guid(),
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

OrganizationMember generateRandomMember({List<MemberRole>? availableRoles}) {
  final roles = availableRoles != null
      ? (availableRoles.toList()..shuffle())
            .take(faker.randomGenerator.integer(3, min: 1))
            .toList()
      : presetRoles();

  return OrganizationMember(
    id: faker.guid.guid(),
    name: faker.person.name(),
    email: faker.internet.email(),
    avatarUrl:
        "https://api.dicebear.com/9.x/avataaars/avif?seed=${faker.guid.guid()}",
    roles: roles,
    joinedAt: faker.date.dateTime(minYear: 2020, maxYear: 2024),
  );
}

class OrganizationRolesMock extends OrganizationRoles {
  OrganizationRolesMock({required this.roles});

  final List<MemberRole> roles;

  @override
  Future<List<MemberRole>> build() async {
    return roles;
  }
}

class OrganizationMembersMock extends OrganizationMembers {
  OrganizationMembersMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<OrganizationMember>> build() async {
    final availableRoles = await ref.watch(organizationRolesProvider.future);
    return await displayState.generate(
      () => generateRandomMember(availableRoles: availableRoles),
    );
  }

  @override
  Future<void> updateMemberRoles(
    String memberId,
    List<MemberRole> roles,
  ) async {
    final members = await future;

    state = AsyncData(
      members.map((member) {
        if (member.id == memberId) {
          return member.copyWith(roles: roles);
        }
        return member;
      }).toList(),
    );
  }

  @override
  Future<void> removeMember(String memberId) async {
    final members = await future;

    state = AsyncData(members.where((m) => m.id != memberId).toList());
  }
}

// ============================================================================
// Join Request Mocks
// ============================================================================

JoinRequest generateRandomJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 5)),
  );
  return JoinRequest(
    id: faker.guid.guid(),
    userId: faker.guid.guid(),
    userName: faker.person.name(),
    userEmail: faker.internet.email(),
    userAvatarUrl:
        "https://api.dicebear.com/9.x/avataaars/avif?seed=${faker.guid.guid()}",
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class OrganizationJoinRequestsMock extends OrganizationJoinRequests {
  OrganizationJoinRequestsMock({required this.displayState, this.onApprove});

  final DisplayState displayState;
  final void Function(JoinRequest request, List<MemberRole> roles)? onApprove;

  @override
  Future<List<JoinRequest>> build() async {
    return await displayState.generate(generateRandomJoinRequest);
  }

  @override
  Future<void> approveRequest(String requestId, List<MemberRole> roles) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final request = requests.firstWhere((r) => r.id == requestId);
    final updated = requests.where((r) => r.id != requestId).toList();
    state = AsyncData(updated);

    onApprove?.call(request, roles);
  }

  @override
  Future<void> declineRequest(String requestId) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final updated = requests.where((r) => r.id != requestId).toList();
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
// User Join Request Mocks (for the user's own pending requests)
// ============================================================================

UserJoinRequest generateRandomUserJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 1)),
  );
  return UserJoinRequest(
    id: faker.guid.guid(),
    organizationId: faker.guid.guid(),
    organizationName: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    organizationIconUrl: generateOrganizationIconUrl(faker.guid.guid()),
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class UserJoinRequestsMock extends UserJoinRequests {
  UserJoinRequestsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Future<List<UserJoinRequest>> build() async {
    return await displayState.generate(generateRandomUserJoinRequest);
  }

  @override
  Future<void> requestToJoin(String urlOrCode) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    final newRequest = generateRandomUserJoinRequest();
    state = AsyncData([newRequest, ...currentRequests]);
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    state = AsyncData(currentRequests.where((r) => r.id != requestId).toList());
  }
}

List<Override> userJoinRequestsProviderOverrides({
  DisplayState state = DisplayState.noItems,
}) => [
  userJoinRequestsProvider.overrideWith(
    () => UserJoinRequestsMock(displayState: state),
  ),
];
