import "dart:async";

import "package:faker/faker.dart";
import "package:flutter/material.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

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
    state.ensureReady();
    final members = state.requireValue;

    final roles = await ensureCorrectRoles(memberId, requestedRoles);

    state = AsyncData(
      members.map((member) {
        if (member.userId == memberId) {
          return member.copyWith(roles: roles);
        }
        return member;
      }).toList(),
    );
  }

  @override
  Future<void> removeMember(skir.RecordId memberId) async {
    state.ensureReady();
    final members = state.requireValue;

    state = AsyncData(members.where((m) => m.userId != memberId).toList());
  }
}

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
