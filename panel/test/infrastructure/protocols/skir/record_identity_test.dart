import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("resource allocation uses typed tables and compact string keys", () {
    for (final resource in AuthoringResource.values) {
      final id = newResourceId(resource);
      expect(id.table, resource.name);
      expect(id.key, isA<skir.RecordIdKey_stringWrapper>());
      expect(id.id, matches(RegExp(r"^[a-z0-9]{20}$")));
    }
  });

  test("opaque keys survive route encoding without database quoting", () {
    for (final key in [
      "abc123",
      "950f5b9a-4a8d-4683-a527-8879d550d790",
      "60000000000000000000000000000001",
      "123",
      "a:b",
      "a b/한글`",
    ]) {
      final id = recordId("page:$key");
      final routeKey = Uri.decodeComponent(Uri.encodeComponent(id.id));
      expect(recordId("page:$routeKey"), id);
      expect(id.id, key);
    }
  });

  test("query rendering is separate from raw string identity", () {
    final id = recordId("page:old-id");
    expect(id.id, "old-id");
    expect(id.toSurrealQl(), "page:`old-id`");
    expect(
      () => skir.RecordId(
        table: "page",
        key: skir.RecordIdKey.wrapNumber(123),
      ).id,
      throwsStateError,
    );
  });
}
