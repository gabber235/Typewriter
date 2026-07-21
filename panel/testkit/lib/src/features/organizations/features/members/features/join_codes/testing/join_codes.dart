import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

// ============================================================================
// Join Code Mocks
// ============================================================================

OrganizationJoinCode generateRandomJoinCode({
  List<OrganizationRole>? availableRoles,
}) {
  final random = faker.randomGenerator;

  // Randomly decide if this code expires or never expires (30% chance never expires)
  final neverExpires = random.boolean() && random.boolean();
  final expiresAt = neverExpires
      ? null
      : DateTime.now().add(Duration(hours: random.integer(168, min: 1)));

  // Randomly decide if single-use (70% chance)
  final singleUse = random.boolean() || random.boolean();

  // Randomly decide if auto-accept (40% chance)
  final hasAutoAccept = random.boolean() && random.boolean();
  final autoAccept = hasAutoAccept && availableRoles != null
      ? JoinCodeAutoAccept(
          roleIds: (availableRoles.toList()..shuffle())
              .take(random.integer(3, min: 1))
              .map((r) => r.roleId)
              .toList(),
        )
      : JoinCodeAutoAccept();

  return OrganizationJoinCode(
    code: recordId("organization_join_code:${generateCode(20)}"),
    createdAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
    singleUse: singleUse,
    autoAccept: autoAccept,
  );
}

class OrganizationJoinCodesMock extends OrganizationJoinCodes {
  OrganizationJoinCodesMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    final availableRoles = await ref.watch(organizationRolesProvider.future);
    yield await displayState.generate(
      () => generateRandomJoinCode(availableRoles: availableRoles),
    );
  }

  @override
  Future<SecretFieldRevealed> generateCode({
    JoinCodeOptions options = const JoinCodeOptions(),
  }) async {
    await Future<void>.delayed(2500.ms);
    final expiresAt = switch (options.expiration) {
      JoinCodeExpirationNever() => null,
      JoinCodeExpirationDuration(:final duration) => DateTime.now().add(
        duration,
      ),
    };
    return SecretFieldRevealed(
      value: "Roft9n2cgVEypNBanD23",
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> revokeCode(skir.RecordId codeId) async {
    await Future.delayed(300.ms);
    final codes = await future;

    final updated = codes.where((c) => c.code != codeId).toList();
    state = AsyncData(updated);
  }
}

List<Override> organizationJoinCodesProviderOverrides({
  DisplayState state = DisplayState.fewItems,
}) => [
  organizationJoinCodesProvider.overrideWith(
    () => OrganizationJoinCodesMock(displayState: state),
  ),
];
