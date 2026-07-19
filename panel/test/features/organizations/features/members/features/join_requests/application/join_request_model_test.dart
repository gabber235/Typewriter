import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

void main() {
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
}
