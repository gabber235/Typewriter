import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

import "support/join_codes_test_support.dart";

void main() {
  OrganizationJoinCode code(String id, DateTime? expiresAt) =>
      OrganizationJoinCode(
        code: recordId("join_code:$id"),
        createdAt: DateTime.utc(2024),
        expiresAt: expiresAt,
      );

  Future<List<OrganizationJoinCode>> cleanup(
    List<OrganizationJoinCode> codes,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        organizationJoinCodesProvider.overrideWith(
          () => MockJoinCodesNotifier(codes),
        ),
      ],
    );
    await readJoinCodes(container);
    container
        .read(organizationJoinCodesProvider.notifier)
        .cleanupExpiredCodes();
    return container.read(organizationJoinCodesProvider).requireValue;
  }

  test("removes expired codes and preserves active code order", () async {
    final first = code("first", DateTime.utc(2100));
    final expired = code("expired", DateTime.utc(2020));
    final last = code("last", null);
    expect(await cleanup([first, expired, last]), [first, last]);
  });

  test("removes all codes when all are expired", () async {
    expect(
      await cleanup([
        code("one", DateTime.utc(2020)),
        code("two", DateTime.utc(2021)),
      ]),
      isEmpty,
    );
  });

  test("preserves codes when none are expired", () async {
    final codes = [code("one", DateTime.utc(2100)), code("two", null)];
    expect(await cleanup(codes), codes);
  });
}
