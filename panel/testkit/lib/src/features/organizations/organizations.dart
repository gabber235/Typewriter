import "dart:async";
export "features/members/members.dart";
import "package:flutter_animate/flutter_animate.dart";

import "package:faker/faker.dart";
import "package:flutter/material.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/features/organizations/organizations.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/utilities/string.dart";
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

OrganizationData generateRandomOrganization() {
  return OrganizationData(
    organizationId: recordId("organization:${faker.guid.guid()}"),
    name: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    logoUrl: generateOrganizationIconUrl(faker.guid.guid()),
  );
}

class OrganizationsMock extends Organizations {
  OrganizationsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<OrganizationData>> build() async* {
    yield await displayState.generate(generateRandomOrganization);
  }

  @override
  Future<skir.RecordId> createOrganization({
    required String name,
    required String logoUrl,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));
    return recordId("organization:${faker.guid.guid()}");
  }
}

class OrganizationProviderMock extends Organization {
  OrganizationProviderMock();

  @override
  Future<OrganizationData?> build() async {
    final organizations = await ref.watch(organizationsProvider.future);
    return organizations.firstOrNull;
  }
}

List<Override> organizationsProviderOverrides({
  DisplayState state = DisplayState.loading,
}) => [
  organizationsProvider.overrideWith(
    () => OrganizationsMock(displayState: state),
  ),
];

List<Override> organizationProviderOverrides() => [
  organizationProvider.overrideWith(() => OrganizationProviderMock()),
  organizationIdProvider.overrideWith(
    (ref) => ref
        .watch(organizationProvider)
        .whenData((value) => value?.organizationId)
        .value,
  ),
];

// ============================================================================
// User Join Request Mocks (for the user's own pending requests)
// ============================================================================

UserJoinRequest generateRandomUserJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 1)),
  );
  return UserJoinRequest(
    requestId: recordId("request_to_join:${faker.guid.guid()}"),
    organizationId: recordId("organization:${faker.guid.guid()}"),
    organizationName: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 2))
        .join(" ")
        .snakeCase(),
    organizationLogoUrl: generateOrganizationIconUrl(faker.guid.guid()),
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class UserJoinRequestsMock extends UserJoinRequests {
  UserJoinRequestsMock({required this.displayState});

  final DisplayState displayState;

  @override
  Stream<List<UserJoinRequest>> build() async* {
    yield await displayState.generate(generateRandomUserJoinRequest);
  }

  @override
  Future<void> requestToJoin(String urlOrCode) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    final newRequest = generateRandomUserJoinRequest();
    state = AsyncData([newRequest, ...currentRequests]);
  }

  @override
  Future<void> cancelRequest(skir.RecordId requestId) async {
    await Future.delayed(300.ms);
    final currentRequests = await future;
    state = AsyncData(
      currentRequests.where((r) => r.requestId != requestId).toList(),
    );
  }
}

List<Override> userJoinRequestsProviderOverrides({
  DisplayState state = DisplayState.noItems,
}) => [
  userJoinRequestsProvider.overrideWith(
    () => UserJoinRequestsMock(displayState: state),
  ),
];
