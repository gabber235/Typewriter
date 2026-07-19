import "dart:async";

import "package:faker/faker.dart";
import "package:flutter_animate/flutter_animate.dart";
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/features/organizations/features/members/application/roles.dart";
import "package:typewriter_panel/features/organizations/features/members/features/join_requests/application/join_requests.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

// Join Request Mocks
// ============================================================================

OrganizationJoinRequest generateRandomJoinRequest() {
  final expiresAt = DateTime.now().add(
    Duration(minutes: faker.randomGenerator.integer(60, min: 5)),
  );
  return OrganizationJoinRequest(
    requestId: recordId("request_to_join:${faker.guid.guid()}"),
    userId: recordId("user:${faker.guid.guid()}"),
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

  @override
  Future<void> approveRequest(
    skir.RecordId requestId,
    List<OrganizationRole> roles,
  ) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final request = requests.firstWhere((r) => r.requestId == requestId);
    final updated = requests.where((r) => r.requestId != requestId).toList();
    state = AsyncData(updated);

    onApprove?.call(request, roles);
  }

  @override
  Future<void> declineRequest(skir.RecordId requestId) async {
    await Future.delayed(300.ms);
    final requests = await future;

    final updated = requests.where((r) => r.requestId != requestId).toList();
    state = AsyncData(updated);
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
