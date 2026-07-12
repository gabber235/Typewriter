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
import "package:typewriter_panel/utils/skir.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _testUserId = "user1";
final _testOrganizationId = recordId("organization:org1");
final _testMemberId = recordId("user:m1");
final _testTimestamp = DateTime.utc(2025, 1, 1, 12);

String get _memberUpdateSubject =>
    "cloud.out.user.$_testUserId.organization.org1.members.update";
String get _memberRemoveSubject =>
    "cloud.out.user.$_testUserId.organization.org1.members.remove";
String get _approveRequestSubject =>
    "cloud.out.user.$_testUserId.organization.$_testOrganizationId.members.join_requests.approve";

OrganizationRole _role({
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

OrganizationMember _member({
  List<OrganizationRole> roles = const [],
  String name = "Test",
  String email = "test@test.com",
  String avatarUrl = "",
  DateTime? joinedAt,
}) => OrganizationMember(
  userId: _testMemberId,
  name: name,
  email: email,
  avatarUrl: avatarUrl,
  roles: roles,
  joinedAt: joinedAt ?? _testTimestamp,
);

/// Reads the first value emitted by an async provider and releases it.
///
/// The subscription callback keeps this helper independent of Riverpod's
/// internal provider types while still handling already-ready providers.
Future<T> _readAsyncData<T>(
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

/// Retains an auto-dispose provider between readiness and command handling.
///
/// A one-shot `.future` read allows disposal before a command runs or while
/// command invalidation rebuilds the provider. Callers must close the returned
/// subscription, normally with `addTearDown`.
Future<ProviderSubscription<AsyncValue<T>>> _retainUntilReady<T>(
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

Future<T> _readProviderValue<T>(
  ProviderSubscription<T> Function(void Function(T? previous, T next))
  subscribe,
) async {
  final result = Completer<T>();
  final subscription = subscribe((previous, next) {
    if (!result.isCompleted) result.complete(next);
  });
  try {
    return await result.future;
  } finally {
    subscription.close();
  }
}

Future<List<OrganizationJoinRequest>> _readJoinRequests(
  ProviderContainer container,
) => _readAsyncData(
  (listener) => container.listen(
    organizationJoinRequestsProvider,
    listener,
    fireImmediately: true,
  ),
);

Future<List<OrganizationJoinCode>> _readJoinCodes(
  ProviderContainer container,
) => _readAsyncData(
  (listener) => container.listen(
    organizationJoinCodesProvider,
    listener,
    fireImmediately: true,
  ),
);

Future<List<OrganizationMember>> _readMembers(ProviderContainer container) =>
    _readAsyncData(
      (listener) => container.listen(
        organizationMembersProvider,
        listener,
        fireImmediately: true,
      ),
    );

Future<List<OrganizationRole>> _readRoles(ProviderContainer container) =>
    _readAsyncData(
      (listener) => container.listen(
        organizationRolesProvider,
        listener,
        fireImmediately: true,
      ),
    );

void main() {
  Future<int> getJoinRequestCount(ProviderContainer container) =>
      _readProviderValue(
        (listener) => container.listen(
          joinRequestCountProvider,
          listener,
          fireImmediately: true,
        ),
      );

  Future<int> getJoinCodeCount(ProviderContainer container) =>
      _readProviderValue(
        (listener) => container.listen(
          joinCodeCountProvider,
          listener,
          fireImmediately: true,
        ),
      );

  group("join request count", () {
    OrganizationJoinRequest createRequest({required bool expired}) {
      final now = DateTime.now();
      return OrganizationJoinRequest(
        requestId: recordId(
          "request_to_join:req-${now.millisecondsSinceEpoch}-${expired ? "exp" : "active"}",
        ),
        userId: recordId("user:user1"),
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
        if (next.hasError && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: true);

      try {
        await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TestFailure(
            "organizationJoinRequestsProvider did not emit AsyncError",
          ),
        );
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

      await _readJoinRequests(container);
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

      await _readJoinRequests(container);
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

      await _readJoinRequests(container);
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

      await _readJoinRequests(container);
      expect(await getJoinRequestCount(container), 2);
    });
  });

  group("join code count", () {
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
        code: recordId("organization_join_codes:CODE-$codeCounter"),
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

      await _readJoinCodes(container);
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

      await _readJoinCodes(container);
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

      await _readJoinCodes(container);
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

      await _readJoinCodes(container);
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

      await _readJoinCodes(container);
      expect(await getJoinCodeCount(container), 4);
    });
  });

  group("OrganizationJoinRequest", () {
    test("isExpired returns true when expiresAt is in the past", () {
      final request = OrganizationJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user1"),
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
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user1"),
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

  group("OrganizationJoinCode", () {
    test("isExpired returns true when expiresAt is in the past", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_codes:ABC123"),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(code.isExpired, true);
      expect(code.neverExpires, false);
      expect(code.remainingDuration, Duration.zero);
    });

    test("isExpired returns false when expiresAt is in the future", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_codes:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(code.isExpired, false);
      expect(code.neverExpires, false);
      expect(code.remainingDuration!.inDays, greaterThanOrEqualTo(6));
    });

    test("neverExpires returns true when expiresAt is null", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_codes:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: null,
      );

      expect(code.neverExpires, true);
      expect(code.isExpired, false);
      expect(code.remainingDuration, null);
    });
  });

  group("OrganizationRole", () {
    test("creates role with all properties", () {
      final role = OrganizationRole(
        roleId: recordId("organization_role:role-1"),
        name: "Admin",
        color: Colors.blue,
        defaultRole: true,
        assignable: false,
        deletable: false,
      );

      expect(role.roleId, recordId("organization_role:role-1"));
      expect(role.name, "Admin");
      expect(role.color, Colors.blue);
      expect(role.defaultRole, true);
      expect(role.assignable, false);
      expect(role.deletable, false);
    });

    test("uses defaults for optional properties", () {
      final role = OrganizationRole(
        roleId: recordId("organization_role:role-1"),
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
        userId: recordId("user:member-1"),
        name: "John Doe",
        email: "john@example.com",
        avatarUrl: "https://example.com/avatar.png",
        roles: [
          OrganizationRole(
            roleId: recordId("organization_role:r1"),
            name: "Admin",
            color: Colors.red,
          ),
        ],
        joinedAt: now,
      );

      expect(member.userId, recordId("user:member-1"));
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
      final autoAccept = JoinCodeAutoAccept(
        roleIds: [
          recordId("organization_role:r1"),
          recordId("organization_role:r2"),
        ],
      );

      expect(autoAccept.roleIds, [
        recordId("organization_role:r1"),
        recordId("organization_role:r2"),
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
        autoAcceptRoleIds: [recordId("organization_role:r1")],
      );

      expect(options.singleUse, false);
      expect(options.expiration, isA<JoinCodeExpirationNever>());
      expect(options.autoAcceptRoleIds, [recordId("organization_role:r1")]);
    });
  });

  group("OrganizationMembers authentication", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test("updateMemberRoles throws when userId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => null),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([_member()]),
          ),
        ],
      );

      await _readMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .updateMemberRoles(recordId("user:m1"), []),
        throwsA(isA<ApiException>()),
      );
    });

    test("updateMemberRoles throws when organizationId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([_member()]),
          ),
        ],
      );

      await _readMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .updateMemberRoles(recordId("user:m1"), []),
        throwsA(isA<ApiException>()),
      );
    });

    test("removeMember throws when userId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => null),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([_member()]),
          ),
        ],
      );

      await _readMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .removeMember(recordId("user:m1")),
        throwsA(isA<ApiException>()),
      );
    });

    test("removeMember throws when organizationId is null", () async {
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([_member()]),
          ),
        ],
      );

      await _readMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .removeMember(recordId("user:m1")),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group("OrganizationMembers command state", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test(
      "removeMember optimistically removes then restores on error",
      () async {
        final member = _member();

        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => _testUserId),
            organizationIdProvider.overrideWith((ref) => _testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([member]),
            ),
          ],
        );

        await _readMembers(container);

        mockNats.registerHandler(_memberRemoveSubject, (data) {
          throw TimeoutException("Connection error");
        });

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .removeMember(_testMemberId),
          throwsA(isA<TimeoutException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.length, 1);
        expect(currentState.value!.first.userId, recordId("user:m1"));
      },
    );

    test("removeMember succeeds when server confirms", () async {
      final member = _member();

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
        ],
      );

      await _readMembers(container);

      mockNats.registerHandler(
        _memberRemoveSubject,
        (data) => skir.RemoveOrganizationMemberResponse.serializer.toBytes(
          skir.RemoveOrganizationMemberResponse.createSuccess(),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .removeMember(recordId("user:m1"));

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.isEmpty, true);
    });

    test(
      "updateMemberRoles optimistically updates then restores on error",
      () async {
        final oldRole = _role(
          id: "r1",
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );
        final newRole = _role(
          id: "r2",
          name: "Admin",
          color: Colors.red,
          assignable: true,
        );

        final member = _member(roles: [oldRole]);

        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => _testUserId),
            organizationIdProvider.overrideWith((ref) => _testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([member]),
            ),
            organizationRolesProvider.overrideWith(
              () => _MockRolesNotifier([oldRole, newRole]),
            ),
          ],
        );

        await _readMembers(container);

        mockNats.registerHandler(_memberUpdateSubject, (data) {
          throw TimeoutException("Connection error");
        });

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .updateMemberRoles(_testMemberId, [newRole]),
          throwsA(isA<TimeoutException>()),
        );

        final currentState = container.read(organizationMembersProvider);
        expect(currentState.value, isNotNull);
        expect(currentState.value!.first.roles.length, 1);
        expect(
          currentState.value!.first.roles.first.roleId,
          recordId("organization_role:r1"),
        );
      },
    );

    test("updateMemberRoles succeeds when server confirms", () async {
      final oldRole = _role(
        id: "r1",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final newRole = _role(
        id: "r2",
        name: "Admin",
        color: Colors.red,
        assignable: true,
      );

      final member = _member(roles: [oldRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([oldRole, newRole]),
          ),
        ],
      );

      await _readMembers(container);

      mockNats.registerHandler(
        _memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [newRole.toSkir()],
            joinedAt: _testTimestamp,
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [newRole]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.roles.length, 1);
      expect(
        currentState.value!.first.roles.first.roleId,
        recordId("organization_role:r2"),
      );
    });
  });

  group("Organization command errors", () {
    late MockNatsClient mockNats;

    setUp(() => mockNats = MockNatsClient());
    tearDown(() => mockNats.dispose());

    Matcher apiException(int code, String message) => isA<ApiException>()
        .having((error) => error.code, "code", code)
        .having((error) => error.message, "message", message);

    OrganizationMember memberWithRole(OrganizationRole role) =>
        _member(roles: [role], email: "", avatarUrl: "");

    test(
      "updateMemberRoles maps unassignable roles and restores state",
      () async {
        final oldRole = _role(
          id: "old",
          name: "Member",
          color: Colors.grey,
          assignable: true,
        );
        final newRole = _role(
          id: "new",
          name: "Admin",
          color: Colors.red,
          assignable: true,
        );
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => _testUserId),
            organizationIdProvider.overrideWith((ref) => _testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([memberWithRole(oldRole)]),
            ),
          ],
        );
        final subscription = await _retainUntilReady<List<OrganizationMember>>(
          (listener) => container.listen(
            organizationMembersProvider,
            listener,
            fireImmediately: true,
          ),
        );
        addTearDown(subscription.close);
        mockNats.registerHandler(
          _memberUpdateSubject,
          (
            data,
          ) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
            skir.UpdateOrganizationMemberRolesResponse.createRolesNotAssignableError(
              roleIds: [newRole.roleId],
            ),
          ),
        );

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .updateMemberRoles(recordId("user:m1"), [newRole]),
          throwsA(apiException(400, "One or more roles cannot be assigned")),
        );
        expect(
          container.read(organizationMembersProvider).requireValue.single.roles,
          [oldRole],
        );
      },
    );

    test("updateMemberRoles maps founder role requirement to conflict", () async {
      final role = _role(
        id: "founder",
        name: "Founder",
        color: Colors.red,
        assignable: true,
      );
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([memberWithRole(role)]),
          ),
        ],
      );
      final subscription = await _retainUntilReady<List<OrganizationMember>>(
        (listener) => container.listen(
          organizationMembersProvider,
          listener,
          fireImmediately: true,
        ),
      );
      addTearDown(subscription.close);
      mockNats.registerHandler(
        _memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createFounderRoleRequiredError(),
        ),
      );

      await expectLater(
        container.read(organizationMembersProvider.notifier).updateMemberRoles(
          recordId("user:m1"),
          [role],
        ),
        throwsA(
          apiException(409, "Organization must retain at least one founder"),
        ),
      );
    });

    test(
      "removeMember maps founder removal conflict and restores state",
      () async {
        final role = OrganizationRole(
          roleId: recordId("organization_role:founder"),
          name: "Founder",
          color: Colors.red,
        );
        final member = memberWithRole(role);
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => _testUserId),
            organizationIdProvider.overrideWith((ref) => _testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationMembersProvider.overrideWith(
              () => _MockMembersNotifier([member]),
            ),
          ],
        );
        final subscription = await _retainUntilReady<List<OrganizationMember>>(
          (listener) => container.listen(
            organizationMembersProvider,
            listener,
            fireImmediately: true,
          ),
        );
        addTearDown(subscription.close);
        mockNats.registerHandler(
          _memberRemoveSubject,
          (data) => skir.RemoveOrganizationMemberResponse.serializer.toBytes(
            skir.RemoveOrganizationMemberResponse.createFounderCannotBeRemovedError(
              userId: member.userId,
            ),
          ),
        );

        await expectLater(
          container
              .read(organizationMembersProvider.notifier)
              .removeMember(member.userId),
          throwsA(apiException(409, "Organization founder cannot be removed")),
        );
        expect(container.read(organizationMembersProvider).requireValue, [
          member,
        ]);
      },
    );

    final approveRequestErrors =
        <
          ({
            String name,
            skir.ApproveOrganizationJoinRequestResponse response,
            int code,
            String message,
          })
        >[
          (
            name: "roles required",
            response: skir
                .ApproveOrganizationJoinRequestResponse.createRolesRequiredError(),
            code: 400,
            message: "At least one role is required",
          ),
          (
            name: "user already member",
            response:
                skir.ApproveOrganizationJoinRequestResponse.createUserAlreadyMemberError(
                  userId: _testMemberId,
                ),
            code: 409,
            message: "User is already an organization member",
          ),
        ];

    for (final outcome in approveRequestErrors) {
      test("approveRequest maps ${outcome.name}", () async {
        final request = OrganizationJoinRequest(
          requestId: recordId("request_to_join:req-1"),
          userId: recordId("user:m1"),
          requestedAt: _testTimestamp,
          expiresAt: _testTimestamp.add(const Duration(days: 1)),
        );
        final container = ProviderContainer.test(
          overrides: [
            userIdProvider.overrideWith((ref) async => _testUserId),
            organizationIdProvider.overrideWith((ref) => _testOrganizationId),
            natsProvider.overrideWithValue(mockNats),
            organizationJoinRequestsProvider.overrideWith(
              () => _MockJoinRequestsNotifier([request]),
            ),
          ],
        );
        final subscription =
            await _retainUntilReady<List<OrganizationJoinRequest>>(
              (listener) => container.listen(
                organizationJoinRequestsProvider,
                listener,
                fireImmediately: true,
              ),
            );
        addTearDown(subscription.close);
        mockNats.registerHandler(
          _approveRequestSubject,
          (data) => skir.ApproveOrganizationJoinRequestResponse.serializer
              .toBytes(outcome.response),
        );

        await expectLater(
          container
              .read(organizationJoinRequestsProvider.notifier)
              .approveRequest(request.requestId, []),
          throwsA(apiException(outcome.code, outcome.message)),
        );
      });
    }
  });

  group("OrganizationMembers.updateMemberRoles role merging", () {
    late MockNatsClient mockNats;

    setUp(() {
      mockNats = MockNatsClient();
    });

    tearDown(() {
      mockNats.dispose();
    });

    test("preserves non-assignable roles from current member", () async {
      final nonAssignableRole = _role(
        id: "owner",
        name: "Owner",
        color: Colors.purple,
        assignable: false,
      );
      final assignableRole = _role(
        id: "editor",
        name: "Editor",
        color: Colors.blue,
        assignable: true,
      );
      final newRole = _role(
        id: "viewer",
        name: "Viewer",
        color: Colors.green,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: recordId("user:m1"),
        name: "Test",
        email: "test@test.com",
        avatarUrl: "",
        roles: [nonAssignableRole, assignableRole],
        joinedAt: _testTimestamp,
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
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

      await _readMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(_memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: _testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [newRole]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:owner")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:viewer")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:editor")),
        false,
      );
    });

    test("only includes assignable roles from requested roles", () async {
      final assignableRole = _role(
        id: "member",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );
      final nonAssignableRequested = _role(
        id: "admin",
        name: "Admin",
        color: Colors.red,
        assignable: false,
      );

      final member = _member(roles: [assignableRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([assignableRole, nonAssignableRequested]),
          ),
        ],
      );

      await _readMembers(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(_memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: _testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [
            assignableRole,
            nonAssignableRequested,
          ]);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:member")),
        true,
      );
      expect(
        capturedRoleIds!.contains(recordId("organization_role:admin")),
        false,
      );
    });

    test("falls back to default roles when result is empty", () async {
      final defaultRole = OrganizationRole(
        roleId: recordId("organization_role:default"),
        name: "Default",
        color: Colors.grey,
        defaultRole: true,
        assignable: true,
      );
      final currentRole = _role(
        id: "member",
        name: "Member",
        color: Colors.blue,
        assignable: true,
      );

      final member = _member(roles: [currentRole]);

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([defaultRole, currentRole]),
          ),
        ],
      );

      await _readMembers(container);
      await _readRoles(container);

      List<skir.RecordId>? capturedRoleIds;
      mockNats.registerHandler(_memberUpdateSubject, (data) {
        final request = skir.UpdateOrganizationMemberRolesRequest.serializer
            .fromBytes(data);
        capturedRoleIds = request.roleIds.toList();
        return skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Test",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: _testTimestamp,
          ),
        );
      });

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), []);

      expect(capturedRoleIds, isNotNull);
      expect(
        capturedRoleIds!.contains(recordId("organization_role:default")),
        true,
      );
      expect(capturedRoleIds!.length, 1);
    });

    test("uses server response to update member", () async {
      final role = _role(
        id: "member",
        name: "Member",
        color: Colors.grey,
        assignable: true,
      );

      final member = OrganizationMember(
        userId: recordId("user:m1"),
        name: "Original Name",
        email: "test@test.com",
        avatarUrl: "",
        roles: [role],
        joinedAt: _testTimestamp,
      );

      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => _testUserId),
          organizationIdProvider.overrideWith((ref) => _testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => _MockMembersNotifier([member]),
          ),
          organizationRolesProvider.overrideWith(
            () => _MockRolesNotifier([role]),
          ),
        ],
      );

      await _readMembers(container);

      mockNats.registerHandler(
        _memberUpdateSubject,
        (data) => skir.UpdateOrganizationMemberRolesResponse.serializer.toBytes(
          skir.UpdateOrganizationMemberRolesResponse.createSuccess(
            userId: recordId("user:m1"),
            name: "Updated Name",
            email: "test@test.com",
            avatarUrl: "",
            roles: [],
            joinedAt: _testTimestamp,
          ),
        ),
      );

      await container
          .read(organizationMembersProvider.notifier)
          .updateMemberRoles(recordId("user:m1"), [role]);

      final currentState = container.read(organizationMembersProvider);
      expect(currentState.value, isNotNull);
      expect(currentState.value!.first.name, "Updated Name");
    });
  });
}

class _LoadingJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    await Completer<void>().future;
  }
}

class _ErrorJoinRequestsNotifier extends OrganizationJoinRequests {
  @override
  Stream<List<OrganizationJoinRequest>> build() =>
      Stream.error(Exception("Test error"));
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
    await Completer<void>().future;
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
