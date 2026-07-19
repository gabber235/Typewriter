import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_codes/application/join_codes.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

import "support/join_codes_test_support.dart";

void main() {
  Future<int> getCount(ProviderContainer container) => readProviderValue(
    (listener) => container.listen(
      joinCodeCountProvider,
      listener,
      fireImmediately: true,
    ),
  );

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
            LoadingJoinCodesNotifier.new,
          ),
        ],
      );

      expect(container.read(joinCodeCountProvider), 0);
    });

    test("returns 0 for empty list", () async {
      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => MockJoinCodesNotifier([]),
          ),
        ],
      );

      await readJoinCodes(container);
      expect(await getCount(container), 0);
    });

    test("returns 0 when all codes are expired", () async {
      final expiredCodes = [
        createCode(expired: true),
        createCode(expired: true),
      ];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => MockJoinCodesNotifier(expiredCodes),
          ),
        ],
      );

      await readJoinCodes(container);
      expect(await getCount(container), 0);
    });

    test("counts never-expires codes as active", () async {
      final codes = [createCode(neverExpires: true)];

      final container = ProviderContainer.test(
        overrides: [
          organizationJoinCodesProvider.overrideWith(
            () => MockJoinCodesNotifier(codes),
          ),
        ],
      );

      await readJoinCodes(container);
      expect(await getCount(container), 1);
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
            () => MockJoinCodesNotifier(mixedCodes),
          ),
        ],
      );

      await readJoinCodes(container);
      expect(await getCount(container), 2);
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
            () => MockJoinCodesNotifier(activeCodes),
          ),
        ],
      );

      await readJoinCodes(container);
      expect(await getCount(container), 4);
    });
  });
}
