import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/api_exception.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/members.dart";
import "package:typewriter_panel/logic/organization/organization.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_testkit/typewriter_testkit.dart";

skir.RecordId _rid(String table, String key) =>
    skir.RecordId(table: table, key: skir.RecordIdKey.wrapString(key));

void main() {
  Future<int> getJoinRequestCount(ProviderContainer container) async {
    final completer = Completer<int>();
    final sub = container.listen(joinRequestCountProvider, (previous, next) {
      if (!completer.isCompleted) {
        completer.complete(next);
      }
    }, fireImmediately: true);
    try {
      return await completer.future;
    } finally {
      sub.close();
    }
  }

  Future<int> getJoinCodeCount(ProviderContainer container) async {
    final completer = Completer<int>();
    final sub = container.listen(joinCodeCountProvider, (previous, next) {
      if (!completer.isCompleted) {
        completer.complete(next);
      }
    }, fireImmediately: true);
    try {
      return await completer.future;
    } finally {
      sub.close();
    }
  }

  Future<List<OrganizationJoinRequest>> waitForJoinRequests(
    ProviderContainer container,
  ) async {
    final completer = Completer<List<OrganizationJoinRequest>>();
    final sub = container.listen(organizationJoinRequestsProvider, (
      previous,
      next,
    ) {
      if (next is AsyncData<List<OrganizationJoinRequest>>) {
        if (!completer.isCompleted) {
          completer.complete(next.value);
        }
      } else if (next is AsyncError) {
        if (!completer.isCompleted) {
          completer.completeError(
            next.error ?? StateError("Unknown error"),
            next.stackTrace,
          );
        }
      }
    }, fireImmediately: true);
    try {
      return await completer.future;
    } finally {
      sub.close();
    }
  }

  Future<List<OrganizationJoinCode>> waitForJoinCodes(
    ProviderContainer container,
  ) async {
    final completer = Completer<List<OrganizationJoinCode>>();
    final sub = container.listen(organizationJoinCodesProvider, (
      previous,
      next,
    ) {
      if (next is AsyncData<List<OrganizationJoinCode>>) {
        if (!completer.isCompleted) {
          completer.complete(next.value);
        }
      } else if (next is AsyncError) {
        if (!completer.isCompleted) {
          completer.completeError(
            next.error ?? StateError("Unknown error"),
            next.stackTrace,
          );
        }
      }
    }, fireImmediately: true);
    try {
      return await completer.future;
    } finally {
      sub.close();
    }
  }

  group("joinRequestCount", () {
    OrganizationJoinRequest createRequest({required bool expired}) {
      final now = DateTime.now();
      return OrganizationJoinRequest(
        requestId: _rid(
          "request_to_join",
          "req-${now.millisecondsSinceEpoch}-${expired ? "exp" : "active"}",
        ),
        userId: _rid("user", "user-1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: now.subtract(const Duration(hours: 1)),
        expiresAt: expired
            ? now.subtract(const Duration(hours: 1))
            : now.add(const Duration(hours: 24)),
      );
    }

    test("returns 0 when provider is loading", () {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            _LoadingJoinRequestsNotifier.new,
          ),
        ],
      );

      expect(container.read(joinRequestCountProvider), 0);
    });

    test("returns 0 when provider has error", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            _ErrorJoinRequestsNotifier.new,
          ),
        ],
      );

      final completer = Completer<void>();
      final sub = container.listen(organizationJoinRequestsProvider, (
        previous,
        next,
      ) {
        if (next is AsyncError && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      try {
        await completer.future.timeout(const Duration(seconds: 2));
      } on TimeoutException catch (_) {
      } finally {
        sub.close();
      }

      expect(container.read(joinRequestCountProvider), 0);
    });

    test("returns 0 for empty list", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => _MockJoinRequestsNotifier([]),
          ),
        ],
      );

      await waitForJoinRequests(container);
      expect(await getJoinRequestCount(container), 0);
    });

    test("returns 0 when all requests are expired", () async {
      final expiredRequests = [
        createRequest(expired: true),
        createRequest(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => _MockJoinRequestsNotifier(expiredRequests),
          ),
        ],
      );

      await waitForJoinRequests(container);
      expect(await getJoinRequestCount(container), 0);
    });

    test("counts all active requests", () async {
      final activeRequests = [
        createRequest(expired: false),
        createRequest(expired: false),
        createRequest(expired: false),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => _MockJoinRequestsNotifier(activeRequests),
          ),
        ],
      );

      await waitForJoinRequests(container);
      expect(await getJoinRequestCount(container), 3);
    });

    test("counts only non-expired requests in mixed list", () async {
      final mixedRequests = [
        createRequest(expired: false),
        createRequest(expired: true),
        createRequest(expired: false),
        createRequest(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinRequestsProvider.overrideWith(
            () => _MockJoinRequestsNotifier(mixedRequests),
          ),
        ],
      );

      await waitForJoinRequests(container);
      expect(await getJoinRequestCount(container), 2);
    });
  });

  group("joinCodeCount", () {
    var codeCounter = 0;

    OrganizationJoinCode createCode({
      bool? expired,
      bool neverExpires = false,
    }) {
      codeCounter++;
      final now = DateTime.now();
      DateTime? expiresAt;
      if (!neverExpires) {
        expiresAt = expired ?? false
            ? now.subtract(const Duration(days: 1))
            : now.add(const Duration(days: 7));
      }
      return OrganizationJoinCode(
        code: _rid("organization_join_codes", "CODE-$codeCounter"),
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: expiresAt,
      );
    }

    test("returns 0 when provider is loading", () {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            _LoadingJoinCodesNotifier.new,
          ),
        ],
      );

      expect(container.read(joinCodeCountProvider), 0);
    });

    test("returns 0 for empty list", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => _MockJoinCodesNotifier([]),
          ),
        ],
      );

      await waitForJoinCodes(container);
      expect(await getJoinCodeCount(container), 0);
    });

    test("returns 0 when all codes are expired", () async {
      final expiredCodes = [
        createCode(expired: true),
        createCode(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => _MockJoinCodesNotifier(expiredCodes),
          ),
        ],
      );

      await waitForJoinCodes(container);
      expect(await getJoinCodeCount(container), 0);
    });

    test("counts never-expires codes as active", () async {
      final codes = [createCode(neverExpires: true)];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => _MockJoinCodesNotifier(codes),
          ),
        ],
      );

      await waitForJoinCodes(container);
      expect(await getJoinCodeCount(container), 1);
    });

    test("counts active and never-expires codes excluding expired", () async {
      final mixedCodes = [
        createCode(expired: false),
        createCode(expired: true),
        createCode(neverExpires: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => _MockJoinCodesNotifier(mixedCodes),
          ),
        ],
      );

      await waitForJoinCodes(container);
      expect(await getJoinCodeCount(container), 2);
    });

    test("counts all non-expired codes", () async {
      final activeCodes = [
        createCode(expired: false),
        createCode(expired: false),
        createCode(neverExpires: true),
        createCode(neverExpires: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => _MockJoinCodesNotifier(activeCodes),
          ),
        ],
      );

      await waitForJoinCodes(container);
      expect(await getJoinCodeCount(container), 4);
    });
  });

  group("JoinRequest", () {
    test("isExpired returns true when expiresAt is in the past", () {
      final request = OrganizationJoinRequest(
        requestId: _rid("request_to_join", "req-1"),
        userId: _rid("user", "user-1"),
        userName: "Test",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(request.isExpired, true);
      expect(request.remainingDuration, Duration.zero);
    });

    test("isExpired returns false when expiresAt is in the future", () {
      final request = OrganizationJoinRequest(
        requestId: _rid("request_to_join", "req-1"),
        userId: _rid("user", "user-1"),
        userName: "Test",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(request.isExpired, false);
      expect(request.remainingDuration.inMinutes, greaterThan(50));
    });
  });

  group("JoinCode", () {
    test("isExpired returns true when expiresAt is in the past", () {
      final code = OrganizationJoinCode(
        code: _rid("organization_join_codes", "ABC123"),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(code.isExpired, true);
      expect(code.neverExpires, false);
      expect(code.remainingDuration, Duration.zero);
    });

    test("isExpired returns false when expiresAt is in the future", () {
      final code = OrganizationJoinCode(
        code: _rid("organization_join_codes", "ABC123"),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(code.isExpired, false);
      expect(code.neverExpires, false);
      expect(code.remainingDuration!.inDays, greaterThanOrEqualTo(6));
    });

    test("neverExpires returns true when expiresAt is null", () {
      final code = OrganizationJoinCode(
        code: _rid("organization_join_codes", "ABC123"),
        createdAt: DateTime.now(),
        expiresAt: null,
      );

      expect(code.neverExpires, true);
      expect(code.isExpired, false);
      expect(code.remainingDuration, null);
    });
  });

  group("MemberRole", () {
    test("creates role with all properties", () {
      final role = OrganizationRole(
        roleId: _rid("organization_role", "role-1"),
        name: "Admin",
        color: Colors.blue,
        defaultRole: true,
        assignable: false,
        deletable: false,
      );

      expect(role.roleId, _rid("organization_role", "role-1"));
      expect(role.name, "Admin");
      expect(role.color, Colors.blue);
      expect(role.defaultRole, true);
      expect(role.assignable, false);
      expect(role.deletable, false);
    });

    test("uses defaults for optional properties", () {
      final role = OrganizationRole(
        roleId: _rid("organization_role", "role-1"),
        name: "Member",
        color: Colors.grey,
      );

      expect(role.defaultRole, false);
      expect(role.assignable, false);
      expect(role.deletable, false);
    });
  });

  group("OrganizationMember", () {
    test("creates member with all properties", () {
      final now = DateTime.now();
      final member = OrganizationMember(
        userId: _rid("user", "member-1"),
        name: "John Doe",
        email: "john@example.com",
        avatarUrl: "https://example.com/avatar.png",
        roles: [
          OrganizationRole(
            roleId: _rid("organization_role", "r1"),
            name: "Admin",
            color: Colors.red,
          ),
        ],
        joinedAt: now,
      );

      expect(member.userId, _rid("user", "member-1"));
      expect(member.name, "John Doe");
      expect(member.email, "john@example.com");
      expect(member.avatarUrl, "https://example.com/avatar.png");
      expect(member.roles.length, 1);
      expect(member.roles.first.name, "Admin");
      expect(member.joinedAt, now);
    });
  });

  group("JoinCodeAutoAccept", () {
    test("creates auto-accept config with role ids", () {
      final autoAccept = JoinCodeAutoAccept(roleIds: [
        _rid("organization_role", "r1"),
        _rid("organization_role", "r2"),
      ]);

      expect(autoAccept.roleIds, [
        _rid("organization_role", "r1"),
        _rid("organization_role", "r2"),
      ]);
    });
  });

  group("JoinCodeOptions", () {
    test("has default values", () {
      const options = JoinCodeOptions();

      expect(options.singleUse, true);
      expect(options.expiration, isA<JoinCodeExpirationDuration>());
      expect(options.autoAcceptRoleIds, isEmpty);
    });

    test("allows custom configuration", () {
      final options = JoinCodeOptions(
        singleUse: false,
        expiration: JoinCodeExpiration.never(),
        autoAcceptRoleIds: [_rid("organization_role", "r1")],
      );

      expect(options.singleUse, false);
      expect(options.expiration, isA<JoinCodeExpirationNever>());
      expect(options.autoAcceptRoleIds, [_rid("organization_role", "r1")]);
    });
  });

  group("Auth Guards", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    Future<List<OrganizationMember>> waitForMembers(
      ProviderContainer container,
    ) async {
      final completer = Completer<List<OrganizationMember>>();
      final sub = container.listen(organizationMembersProvider, (
        previous,
        next,
      ) {
        if (next is AsyncData<List<OrganizationMember>>) {
          if (!completer.isCompleted) {
            completer.complete(next.value);
          }
        }
      }, fireImmediately: true);
      try {
        return await completer.future;
      } finally {
        sub.close();
      }
    }

    test("updateMemberRoles throws when userId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => null),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([
              OrganizationMember(
                userId: _rid("user", "m1"),
                name: "Test",
                email: "test@test.com",
                avatarUrl: "",
                roles: [],
                joinedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      await waitForMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .updateMemberRoles(_rid("user", "m1"), []),
        throwsA(isA<ApiException>()),
      );
    });

    test("updateMemberRoles throws when organizationId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([
              OrganizationMember(
                userId: _rid("user", "m1"),
                name: "Test",
                email: "test@test.com",
                avatarUrl: "",
                roles: [],
                joinedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      await waitForMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .updateMemberRoles(_rid("user", "m1"), []),
        throwsA(isA<ApiException>()),
      );
    });

    test("removeMember throws when userId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => null),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([
              OrganizationMember(
                userId: _rid("user", "m1"),
                name: "Test",
                email: "test@test.com",
                avatarUrl: "",
                roles: [],
                joinedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      await waitForMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .removeMember(_rid("user", "m1")),
        throwsA(isA<ApiException>()),
      );
    });

    test("removeMember throws when organizationId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([
              OrganizationMember(
                userId: _rid("user", "m1"),
                name: "Test",
                email: "test@test.com",
                avatarUrl: "",
                roles: [],
                joinedAt: DateTime.now(),
              ),
            ]),
          ),
        ],
      );

      await waitForMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .removeMember(_rid("user", "m1")),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group("Optimistic Updates", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    Future<List<OrganizationMember>> waitForMembers(
      ProviderContainer container,
    ) async {
      final completer = Completer<List<OrganizationMember>>();
      final sub = container.listen(organizationMembersProvider, (
        previous,
        next,
      ) {
        if (next is AsyncData<List<OrganizationMember>>) {
          if (!completer.isCompleted) {
            completer.complete(next.value);
          }
        }
      }, fireImmediately: true);
      try {
        return await completer.future;
      } finally {
        sub.close();
      }
    }

    test(
      "removeMember optimistically removes then restores on error",
      () async {
        final member = OrganizationMember(
          userId: _rid("user", "m1"),
          name: "Test",
          email: "test@test.com",
          avatarUrl: "",
          roles: [],
          joinedAt: DateTime.now(),
        );

        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => "user-1"),
            organizationIdProvider.overrideWith(
              (ref) => _rid("organization", "org-1"),
            ),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([member]),
            ),
          ],
        );

        await waitForMembers(container);

        mockNats.registerHandler(
          "cloud.out.user.user-1.organization.org-1.members.remove",
          (data) {
            throw TimeoutException("Connection error");
          },
        );

        try {
          await container
              .read(organizationMembersProvider.notifier)
              .removeMember(_rid("user", "m1"));
        } on Exception catch (_) {}

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.length, 1);
        expect(currentState.value!.first.userId, _rid("user", "m1"));
      },
    );

    test("removeMember succeeds when server confirms", () async {
      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [],
        joinedAt: DateTime.now(),
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
        ],
      );

      await waitForMembers(container);

      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.remove",
        (data) => skir.RemoveOrganizationMemberResponse.serializer.toBytes(
          skir.RemoveOrganizationMemberResponse.createSuccess(),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .removeMember(_rid("user", "m1"));

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.isEmpty, true);
    });

    test(
      "updateMemberRoles optimistically updates then restores on error",
      () async {
        final oldRole = OrganizationRole(
          roleId: _rid("organization_role", "r1"),
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );
        final newRole = OrganizationRole(
          roleId: _rid("organization_role", "r2"),
          name: "Admin",
          color: Colors.red,
          assignable: true,
        );

        final member = OrganizationMember(
          userId: _rid("user", "m1"),
          name: "Test",
          email: "test@test.com",
          avatarUrl: "",
          roles: [oldRole],
          joinedAt: DateTime.now(),
        );

        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => "user-1"),
            organizationIdProvider.overrideWith(
              (ref) => _rid("organization", "org-1"),
            ),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([member]),
            ),
            organizationRolesProvider.overrideWith(
              () => _MockRolesNotifier([oldRole, newRole]),
            ),
          ],
        );

        await waitForMembers(container);

        mockNats.registerHandler(
          "cloud.out.user.user-1.organization.org-1.members.update",
          (data) {
            throw TimeoutException("Connection error");
          },
        );

        try {
          await container
              .read(organizationMembersProvider.notifier)
              .updateMemberRoles(_rid("user", "m1"), [newRole]);
        } on Exception catch (_) {}

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.first.roles.length, 1);
        expect(
          currentState.value!.first.roles.first.roleId,
          _rid("organization_role", "r1"),
        );
      },
    );

    test("updateMemberRoles succeeds when server confirms", () async {
      final oldRole = OrganizationRole(
        roleId: _rid("organization_role", "r1"),
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final newRole = OrganizationRole(
        roleId: _rid("organization_role", "r2"),
        name: "Admin",
        color: Colors.red,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [oldRole],
        joinedAt: DateTime.now(),
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([oldRole, newRole]),
          ),
        ],
      );

      await waitForMembers(container);

      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.update",
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer
            .toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: _rid("user", "m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: DateTime.now(),
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(_rid("user", "m1"), [newRole]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.roles.length, 1);
      expect(
        currentState.value!.first.roles.first.roleId,
        _rid("organization_role", "r2"),
      );
    });
  });

  group("Role Merging Logic", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    Future<List<OrganizationMember>> waitForMembers(
      ProviderContainer container,
    ) async {
      final completer = Completer<List<OrganizationMember>>();
      final sub = container.listen(organizationMembersProvider, (
        previous,
        next,
      ) {
        if (next is AsyncData<List<OrganizationMember>>) {
          if (!completer.isCompleted) {
            completer.complete(next.value);
          }
        }
      }, fireImmediately: true);
      try {
        return await completer.future;
      } finally {
        sub.close();
      }
    }

    test("preserves non-assignable roles from current member", () async {
      final nonAssignableRole = OrganizationRole(
        roleId: _rid("organization_role", "owner"),
        name: "Owner",
        color: Colors.purple,
        assignable: false,
      );
      final assignableRole = OrganizationRole(
        roleId: _rid("organization_role", "editor"),
        name: "Editor",
        color: Colors.blue,
        assignable: true,
      );
      final newRole = OrganizationRole(
        roleId: _rid("organization_role", "viewer"),
        name: "Viewer",
        color: Colors.green,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [nonAssignableRole, assignableRole],
        joinedAt: DateTime.now(),
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([
              nonAssignableRole,
              assignableRole,
              newRole,
            ]),
          ),
        ],
      );

      await waitForMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.update",
        (data) {
          final request =
              skir.UpdateOrganizationMemberRolesRequest.serializer.fromBytes(
            data,
          );
          capturedRoleIds = request.roleIds.toList();
          return skir.UpdateOrganizationMemberRolesResponse.serializer
              .toBytes(
            skir.UpdateOrganizationMemberRolesResponse.createSuccess(
              userId: _rid("user", "m1"),
              name: "Test",
              email: "test@test.com",
              avatarUrl: "",
              roles: [],
              joinedAt: DateTime.now(),
            ),
          );
        },
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(_rid("user", "m1"), [newRole]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "owner")),
        true,
      );
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "viewer")),
        true,
      );
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "editor")),
        false,
      );
    });

    test("only includes assignable roles from requested roles", () async {
      final assignableRole = OrganizationRole(
        roleId: _rid("organization_role", "member"),
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final nonAssignableRequested = OrganizationRole(
        roleId: _rid("organization_role", "admin"),
        name: "Admin",
        color: Colors.red,
        assignable: false,
      );

      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [assignableRole],
        joinedAt: DateTime.now(),
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () =>
                _MockRolesNotifier([assignableRole, nonAssignableRequested]),
          ),
        ],
      );

      await waitForMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.update",
        (data) {
          final request =
              skir.UpdateOrganizationMemberRolesRequest.serializer.fromBytes(
            data,
          );
          capturedRoleIds = request.roleIds.toList();
          return skir.UpdateOrganizationMemberRolesResponse.serializer
              .toBytes(
            skir.UpdateOrganizationMemberRolesResponse.createSuccess(
              userId: _rid("user", "m1"),
              name: "Test",
              email: "test@test.com",
              avatarUrl: "",
              roles: [],
              joinedAt: DateTime.now(),
            ),
          );
        },
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(_rid("user", "m1"), [
        assignableRole,
        nonAssignableRequested,
      ]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "member")),
        true,
      );
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "admin")),
        false,
      );
    });

    test("falls back to default roles when result is empty", () async {
      final defaultRole = OrganizationRole(
        roleId: _rid("organization_role", "default"),
        name: "Default",
        color: Colors.grey,
        defaultRole: true,
        assignable: true,
      );
      final currentRole = OrganizationRole(
        roleId: _rid("organization_role", "member"),
        name: "Member",
        color: Colors.blue,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [currentRole],
        joinedAt: DateTime.now(),
      );

      Future<List<OrganizationRole>> waitForRoles(
        ProviderContainer container,
      ) async {
        final completer = Completer<List<OrganizationRole>>();
        final sub = container.listen(organizationRolesProvider, (
          previous,
          next,
        ) {
          if (next is AsyncData<List<OrganizationRole>>) {
            if (!completer.isCompleted) {
              completer.complete(next.value);
            }
          }
        }, fireImmediately: true);
        try {
          return await completer.future;
        } finally {
          sub.close();
        }
      }

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([defaultRole, currentRole]),
          ),
        ],
      );

      await waitForMembers(container);
      await waitForRoles(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.update",
        (data) {
          final request =
              skir.UpdateOrganizationMemberRolesRequest.serializer.fromBytes(
            data,
          );
          capturedRoleIds = request.roleIds.toList();
          return skir.UpdateOrganizationMemberRolesResponse.serializer
              .toBytes(
            skir.UpdateOrganizationMemberRolesResponse.createSuccess(
              userId: _rid("user", "m1"),
              name: "Test",
              email: "test@test.com",
              avatarUrl: "",
              roles: [],
              joinedAt: DateTime.now(),
            ),
          );
        },
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(_rid("user", "m1"), []);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(_rid("organization_role", "default")),
        true,
      );
      expect(capturedRoleIds!.length, 1);
    });

    test("uses server response to update member", () async {
      final role = OrganizationRole(
        roleId: _rid("organization_role", "member"),
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: _rid("user", "m1"),
        name: "Original Name",
        email: "test@test.com",
        avatarUrl: "",
        roles: [role],
        joinedAt: DateTime.now(),
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user-1"),
          organizationIdProvider.overrideWith(
            (ref) => _rid("organization", "org-1"),
          ),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([role]),
          ),
        ],
      );

      await waitForMembers(container);

      mockNats.registerHandler(
        "cloud.out.user.user-1.organization.org-1.members.update",
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer
            .toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: _rid("user", "m1"),
            name: "Updated Name",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: DateTime.now(),
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(_rid("user", "m1"), [role]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.name, "Updated Name");
    });
  });
}

class _LoadingJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    await Future<void>.delayed(const Duration(hours: 1));
  }
}

class _ErrorJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    throw Exception("Test error");
  }
}

class _MockJoinRequestsNotifier extends OrganizationJoinRequests {
  _MockJoinRequestsNotifier(this._requests);
  final List<OrganizationJoinRequest> _requests;

  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    yield _requests;
  }
}

class _LoadingJoinCodesNotifier extends OrganizationJoinCodes {
  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    await Future<void>.delayed(const Duration(hours: 1));
  }
}

class _MockJoinCodesNotifier extends OrganizationJoinCodes {
  _MockJoinCodesNotifier(this._codes);
  final List<OrganizationJoinCode> _codes;

  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    yield _codes;
  }
}

class _MockMembersNotifier extends OrganizationMembers {
  _MockMembersNotifier(this._members);
  final List<OrganizationMember> _members;

  @override
  Stream<List<OrganizationMember>> build() async* {
    yield _members;
  }
}

class _MockRolesNotifier extends OrganizationRoles {
  _MockRolesNotifier(this._roles);
  final List<OrganizationRole> _roles;

  @override
  Stream<List<OrganizationRole>> build() async* {
    yield _roles;
  }
}
