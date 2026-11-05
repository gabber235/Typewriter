import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _code = joinCode("first");
final _codes = skir.WatchOrganizationJoinCodesRequest().operation(
  userId: ada.id,
  organizationId: acme.organizationId,
);
final _services = skir.WatchOrganizationServicesRequest().operation(
  userId: ada.id,
  organizationId: acme.organizationId,
);

void main() {
  test(
    "worlds built from one trait list never share a membership service",
    () async {
      final traits = [
        signedIn(ada, organization: acme),
        membershipService(joinCodes: [_code]),
      ];
      final first = testWorld(traits);
      await first.nats.answer(
        skir.RevokeOrganizationJoinCodeRequest(codeId: _code.code)
            .operation(userId: ada.id, organizationId: acme.organizationId),
      );

      final second = testWorld(traits);

      expect(
        await first.nats.answer(_codes),
        isA<skir.WatchOrganizationJoinCodesResponse_snapshotWrapper>().having(
          (response) => response.value.values,
          "join codes",
          isEmpty,
        ),
      );
      expect(
        await second.nats.answer(_codes),
        isA<skir.WatchOrganizationJoinCodesResponse_snapshotWrapper>().having(
          (response) => response.value.values,
          "join codes",
          [_code],
        ),
      );
    },
  );

  test(
    "worlds built from one trait list never share a services backend",
    () async {
      final lobby = service("Lobby");
      final traits = [
        signedIn(ada, organization: acme),
        servicesService(services: [lobby]),
      ];
      final first = testWorld(traits);
      await first.nats.answer(
        skir.UpdateOrganizationServiceRequest(
          serviceId: lobby.serviceId,
          expectedRevision: lobby.revision,
          name: "Hall",
        ).operation(userId: ada.id, organizationId: acme.organizationId),
      );

      final second = testWorld(traits);

      expect(
        await first.nats.answer(_services),
        isA<skir.WatchOrganizationServicesResponse_listWrapper>().having(
          (response) => [for (final service in response.value) service.name],
          "service names",
          ["Hall"],
        ),
      );
      expect(
        await second.nats.answer(_services),
        isA<skir.WatchOrganizationServicesResponse_listWrapper>().having(
          (response) => [for (final service in response.value) service.name],
          "service names",
          ["Lobby"],
        ),
      );
    },
  );
}
