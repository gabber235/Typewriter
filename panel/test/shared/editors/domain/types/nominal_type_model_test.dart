import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("qualified type identities distinguish namespaces and revisions", () {
    const first = QualifiedTypeId(namespace: "example/v1", name: "Entry");
    const otherNamespace = QualifiedTypeId(
      namespace: "example/v2",
      name: "Entry",
    );

    expect(first, isNot(otherNamespace));
    expect(
      const ResolvedTypeRef(id: first, revision: 1),
      isNot(const ResolvedTypeRef(id: first, revision: 2)),
    );
  });
}
