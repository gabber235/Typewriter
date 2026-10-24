import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final organization = skir.RecordId(
    table: "organization",
    key: skir.RecordIdKey.wrapString("writers"),
  );
  final realm = skir.RecordId(
    table: "realm",
    key: skir.RecordIdKey.wrapString("quests"),
  );

  group("generated route outcomes", () {
    test("follow the Skir variant names", () {
      final operation = skir.UnbindServiceRequest(serviceId: "host")
          .operation(userId: "writer", organizationId: organization);

      expect(
        operation.outcome(skir.UnbindServiceResponse.createSuccess()),
        ResponseOutcome.success,
      );
      expect(
        operation.outcome(
          skir.UnbindServiceResponse.createServiceNotFoundError(),
        ),
        ResponseOutcome.domainError,
      );
      expect(
        operation.outcome(skir.UnbindServiceResponse.createInternalError()),
        ResponseOutcome.internalError,
      );
      expect(
        operation.outcome(skir.UnbindServiceResponse.unknown),
        ResponseOutcome.internalError,
      );
    });

    test("report an artifact conflict as a domain error", () {
      final operation = skir.PublishSharedArtifactRequest.defaultInstance
          .operation(organizationId: organization, realmId: realm);

      expect(
        operation.outcome(
          skir.PublishSharedArtifactResponse.wrapConflictError(null),
        ),
        ResponseOutcome.domainError,
      );
      expect(
        operation.outcome(
          skir.PublishSharedArtifactResponse.createInternalError(),
        ),
        ResponseOutcome.internalError,
      );
    });
  });
}
