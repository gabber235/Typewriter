import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("catalog routes remain isolated by organization and Realm", () {
    final route = RealmEditorCatalogRoute(
      organizationId: skir.recordId("organization:alpha"),
      realmId: skir.recordId("service:beta"),
    );

    expect(
      route.fetchSubject,
      "service.to.beta.organization.alpha.realm.editor.catalog.fetch",
    );
    expect(
      route.fetchUpdateSubject("transfer_1"),
      "service.from.beta.organization.alpha.realm.editor.catalog.fetch.transfer_1",
    );
    expect(
      route.invalidationRequestSubject,
      "service.to.beta.organization.alpha.realm.editor.catalog.invalidate",
    );
    expect(
      route.invalidationSubject,
      "service.from.beta.organization.alpha.realm.editor.catalog.invalidate",
    );
  });

  test("catalog transfer update subjects require one safe segment", () {
    final route = RealmEditorCatalogRoute(
      organizationId: skir.recordId("organization:alpha"),
      realmId: skir.recordId("service:beta"),
    );

    for (final invalid in ["", "two.parts", "wildcard.*", "space value"]) {
      expect(
        () => route.fetchUpdateSubject(invalid),
        throwsA(isA<ArgumentError>()),
      );
    }
  });
}
