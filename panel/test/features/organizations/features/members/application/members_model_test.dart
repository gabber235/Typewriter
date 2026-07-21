import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
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
}
