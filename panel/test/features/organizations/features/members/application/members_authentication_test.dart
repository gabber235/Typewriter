import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "support/members_test_support.dart";

void main() {
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
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([createMember()]),
          ),
        ],
      );

      await readMembers(container);

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
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([createMember()]),
          ),
        ],
      );

      await readMembers(container);

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
          organizationIdProvider.overrideWith((ref) => testOrganizationId),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([createMember()]),
          ),
        ],
      );

      await readMembers(container);

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
          userIdProvider.overrideWith((ref) async => testUserId),
          organizationIdProvider.overrideWith((ref) => null),
          natsProvider.overrideWithValue(mockNats),
          organizationMembersProvider.overrideWith(
            () => MockMembersNotifier([createMember()]),
          ),
        ],
      );

      await readMembers(container);

      expect(
        () => container
            .read(organizationMembersProvider.notifier)
            .removeMember(recordId("user:m1")),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
