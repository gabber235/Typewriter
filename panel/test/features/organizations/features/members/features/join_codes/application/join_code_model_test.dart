import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("OrganizationJoinCode", () {
    test("isExpired returns true when expiresAt is in the past", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(code.isExpired, true);
      expect(code.neverExpires, false);
      expect(code.remainingDuration, Duration.zero);
    });

    test("isExpired returns false when expiresAt is in the future", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(code.isExpired, false);
      expect(code.neverExpires, false);
      expect(code.remainingDuration!.inDays, greaterThanOrEqualTo(6));
    });

    test("neverExpires returns true when expiresAt is null", () {
      final code = OrganizationJoinCode(
        code: recordId("organization_join_code:ABC123"),
        createdAt: DateTime.now(),
        expiresAt: null,
      );

      expect(code.neverExpires, true);
      expect(code.isExpired, false);
      expect(code.remainingDuration, null);
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
}
