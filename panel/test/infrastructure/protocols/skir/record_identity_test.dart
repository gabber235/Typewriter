import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("opaque keys survive route encoding without database quoting", () {
    for (final key in [
      "abc123",
      "950f5b9a-4a8d-4683-a527-8879d550d790",
      "60000000000000000000000000000001",
      "123",
      "a:b",
      "a b/한글`",
    ]) {
      final id = skir.recordId("page:$key");
      final routeKey = Uri.decodeComponent(Uri.encodeComponent(id.id));
      expect(skir.recordId("page:$routeKey"), id);
      expect(id.id, key);
    }
  });

  test("a numeric record key has no route id", () {
    expect(
      () => skir.RecordId(
        table: "page",
        key: skir.RecordIdKey.wrapNumber(123),
      ).id,
      throwsStateError,
    );
  });

  test("route ids without a table or key are refused", () {
    for (final malformed in [":x", "x:", "x", ""]) {
      expect(
        () => skir.recordId(malformed),
        throwsArgumentError,
        reason: malformed,
      );
    }
  });

  test("new resource ids are 20 lowercase alphanumeric characters", () {
    final ids = {
      for (var index = 0; index < 100; index++) skir.newResourceId().value,
    };

    expect(ids, hasLength(100));
    expect(ids, everyElement(matches(RegExp(r"^[a-z0-9]{20}$"))));
  });
}
