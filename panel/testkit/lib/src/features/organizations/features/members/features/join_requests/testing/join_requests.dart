import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:faker/faker.dart";

// ignore: depend_on_referenced_packages, implementation_imports

import "package:typewriter_testkit/src/shared/testing/testing.dart";

// Join Request Mocks
// ============================================================================

OrganizationJoinRequest generateRandomJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 5)),
  );
  return OrganizationJoinRequest(
    requestId: skir.recordId("request_to_join:${faker.guid.guid()}"),
    userId: skir.recordId("user:${faker.guid.guid()}"),
    userName: faker.person.name(),
    userEmail: faker.internet.email(),
    userAvatarUrl:
        "https://api.dicebear.com/9.x/avataaars/webp?seed=${faker.guid.guid()}",
    requestedAt: faker.date.dateTime(minYear: 2024, maxYear: 2025),
    expiresAt: expiresAt,
  );
}

class OrganizationJoinRequestsMock extends OrganizationJoinRequests {
  OrganizationJoinRequestsMock({required this.displayState, this.onApprove});

  final DisplayState displayState;
  final void Function(
    OrganizationJoinRequest request,
    List<OrganizationRole> roles,
  )?
  onApprove;

  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
    yield await displayState.generate(generateRandomJoinRequest);
  }
}

// ============================================================================
// Override Helpers
// ============================================================================

List<Override> organizationJoinRequestsProviderOverrides({
  DisplayState state = DisplayState.fewItems,
}) => [
  organizationJoinRequestsProvider.overrideWith(
    () => OrganizationJoinRequestsMock(displayState: state),
  ),
];

// ============================================================================
