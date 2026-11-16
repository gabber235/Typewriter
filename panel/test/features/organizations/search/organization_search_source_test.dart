import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final globex = organization("Globex");

  test("an empty search lists every organization and Create "
      "Organization", () async {
    final list = DrivenList<List<skir.Organization>>();
    await list.emit([acme, globex]);
    final results = resultsOf(
      await firstSnapshot(organizationsSearchSource, list),
    );

    expect(
      results.map((result) => result.title),
      unorderedEquals(["Acme", "Globex", "Create Organization"]),
    );
  });

  test("Create Organization is found by its name", () async {
    final list = DrivenList<List<skir.Organization>>();
    await list.emit([acme]);
    final results = resultsOf(
      await firstSnapshot(organizationsSearchSource, list, query: "create"),
    );

    expect(results.map((result) => result.type), [
      createOrganizationSearchResultType,
    ]);
  });

  test("while organizations reload, the known ones stay listed and marked "
      "stale", () async {
    final list = DrivenList<List<skir.Organization>>();
    await list.emit([acme]);
    await list.changeScope();
    final snapshot = await firstSnapshot(
      organizationsSearchSource,
      list,
      query: "acme",
    );

    expect(snapshot.status, SearchSourceStatus.loading);
    expect(resultsOf(snapshot).single.title, "Acme");
    expect(resultsOf(snapshot).single.isStale, isTrue);
  });
}
