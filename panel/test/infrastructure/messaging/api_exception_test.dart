import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

void main() {
  test("invalid record ID errors preserve table details", () {
    final error = skir.InvalidRecordIdError(
      expectedTable: "organization_role",
      givenTables: ["service", "user"],
    );

    final exception = ApiException.invalidRecordId(error);

    expect(exception.code, 400);
    expect(
      exception.message,
      "Expected record IDs from table 'organization_role', but received tables: 'service', 'user'.",
    );
  });
}
