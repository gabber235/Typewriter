import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/application/user_join_requests.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

void main() {
  group("JoinRequest expiration", () {
    test("isExpired returns false when expiresAt is in the future", () {
      final request = OrganizationJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user-1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(request.isExpired, isFalse);
    });

    test("isExpired returns true when expiresAt is in the past", () {
      final request = OrganizationJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user-1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(request.isExpired, isTrue);
    });

    test("remainingDuration calculates correctly for future expiry", () {
      final expiresAt = DateTime.now().add(const Duration(hours: 2));
      final request = OrganizationJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user-1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      final remaining = request.remainingDuration;
      expect(remaining.inMinutes, greaterThanOrEqualTo(119));
      expect(remaining.inMinutes, lessThanOrEqualTo(120));
    });

    test("remainingDuration returns zero for past expiry", () {
      final request = OrganizationJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        userId: recordId("user:user-1"),
        userName: "Test User",
        userEmail: "test@example.com",
        userAvatarUrl: "https://example.com/avatar.png",
        requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(request.remainingDuration, Duration.zero);
    });
  });

  group("JoinCode expiration", () {
    test("isExpired returns false when expiresAt is null (never expires)", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: null,
      );

      expect(code.isExpired, isFalse);
      expect(code.neverExpires, isTrue);
    });

    test("isExpired returns false when expiresAt is in the future", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(code.isExpired, isFalse);
      expect(code.neverExpires, isFalse);
    });

    test("isExpired returns true when expiresAt is in the past", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        expiresAt: DateTime.now().subtract(const Duration(days: 7)),
      );

      expect(code.isExpired, isTrue);
    });

    test("remainingDuration returns null when never expires", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: null,
      );

      expect(code.remainingDuration, isNull);
    });

    test("remainingDuration returns zero for past expiry", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(code.remainingDuration, Duration.zero);
    });
  });

  group("UserJoinRequest expiration", () {
    test("isExpired returns false when expiresAt is in the future", () {
      final request = UserJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        organizationId: recordId("organization:org-1"),
        organizationName: "Test Org",
        organizationLogoUrl: "https://example.com/icon.png",
        requestedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      expect(request.isExpired, isFalse);
    });

    test("isExpired returns true when expiresAt is in the past", () {
      final request = UserJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        organizationId: recordId("organization:org-1"),
        organizationName: "Test Org",
        organizationLogoUrl: "https://example.com/icon.png",
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(request.isExpired, isTrue);
    });

    test("remainingDuration returns zero for expired request", () {
      final request = UserJoinRequest(
        requestId: recordId("request_to_join:req-1"),
        organizationId: recordId("organization:org-1"),
        organizationName: "Test Org",
        organizationLogoUrl: "https://example.com/icon.png",
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(request.remainingDuration, Duration.zero);
    });
  });

  group("MemberRole model", () {
    test("creates role with all fields", () {
      final role = OrganizationRole(
        roleId: recordId("organization_role:role-1"),
        name: "Editor",
        color: Colors.blue,
        defaultRole: true,
        assignable: true,
        deletable: false,
      );

      expect(role.roleId, recordId("organization_role:role-1"));
      expect(role.name, "Editor");
      expect(role.color, Colors.blue);
      expect(role.defaultRole, isTrue);
      expect(role.assignable, isTrue);
      expect(role.deletable, isFalse);
    });

    test("uses correct defaults", () {
      final role = OrganizationRole(
        roleId: recordId("organization_role:role-1"),
        name: "Member",
        color: Colors.grey,
      );

      expect(role.defaultRole, isFalse);
      expect(role.assignable, isFalse);
      expect(role.deletable, isFalse);
    });
  });

  group("JoinCodeOptions model", () {
    test("creates options with defaults", () {
      const options = JoinCodeOptions();

      expect(options.singleUse, isTrue);
      expect(
        options.expiration,
        const JoinCodeExpiration.duration(Duration(days: 7)),
      );
      expect(options.autoAcceptRoleIds, isEmpty);
    });

    test("creates options with never expiration", () {
      final options = JoinCodeOptions(
        expiration: JoinCodeExpiration.never(),
        singleUse: false,
        autoAcceptRoleIds: [
          recordId("organization_role:role-1"),
          recordId("organization_role:role-2"),
        ],
      );

      expect(options.singleUse, isFalse);
      expect(options.expiration, const JoinCodeExpiration.never());
      expect(options.autoAcceptRoleIds, [
        recordId("organization_role:role-1"),
        recordId("organization_role:role-2"),
      ]);
    });

    test("creates options with custom duration", () {
      const options = JoinCodeOptions(
        expiration: JoinCodeExpiration.duration(Duration(hours: 48)),
      );

      expect(
        options.expiration,
        const JoinCodeExpiration.duration(Duration(hours: 48)),
      );
    });
  });

  group("JoinCodeExpiration sealed class", () {
    test("never pattern matches correctly", () {
      const expiration = JoinCodeExpiration.never();

      final result = switch (expiration) {
        JoinCodeExpirationNever() => "never",
        JoinCodeExpirationDuration(:final duration) => "duration: $duration",
      };

      expect(result, "never");
    });

    test("duration pattern matches correctly", () {
      const expiration = JoinCodeExpiration.duration(Duration(days: 3));

      final result = switch (expiration) {
        JoinCodeExpirationNever() => "never",
        JoinCodeExpirationDuration(:final duration) => duration.inDays,
      };

      expect(result, 3);
    });
  });
}
