import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/architecture.dart";

void main() {
  test("the declared module graph is acyclic", () {
    expect(cyclesIn(panelModules), isEmpty);
  });

  test("every panel library belongs to a declared module", () {
    final unmapped = Directory("lib")
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith(".dart") && !isGeneratedOrBarrel(file.path),
        )
        .where(
          (file) => tryModuleOf(file.path.substring("lib/".length)) == null,
        )
        .map((file) => file.path);
    expect(unmapped, isEmpty);
  });

  test("only the dependency library and main own root files", () {
    expect(tryModuleOf("dependencies.dart")?.path, "dependencies");
    expect(tryModuleOf("dependencies_io_stub.dart")?.path, "dependencies");
    expect(tryModuleOf("main.dart")?.path, "app");
    expect(tryModuleOf("helpers.dart"), isNull);
  });

  test("modules depend only on modules below them", () async {
    final root = Directory("lib").absolute.path;
    final scan = await scanModules(
      AnalysisContextCollection(includedPaths: [root], sdkPath: dartSdkPath()),
      root,
    );
    expect(scan.unresolved, isEmpty);
    // Positive control: if resolution silently failed, no edge would be seen at all.
    expect(scan.observed, contains(("shared/ui", "shared/theme")));
    expect(scan.violations.map((violation) => "$violation"), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));

  group("the reference rule", () {
    const routeUse = """
import "package:typewriter_panel/typewriter_panel.dart";

PageRouteInfo<Object?> organizationHome() =>
    OrganizationRoute(organizationId: "organization");
""";
    const fixtures = {
      "shared/editors/application/selection_fixture.dart": """
import "package:typewriter_panel/typewriter_panel.dart";

Object selected(Ref ref) => ref.watch(selectionProvider);
""",
      "shared/navigation/application/route_fixture.dart": routeUse,
      "authoring/application/route_fixture.dart": routeUse,
      "features/realms/application/route_fixture.dart": routeUse,
      "features/realms/application/amount_fixture.dart": """
class Amount {
  const Amount(this.value);
  final int value;
  Amount operator +(Amount other) => Amount(value + other.value);
  Amount operator -() => Amount(-value);
  int operator [](int index) => value;
  void operator []=(int index, int next) {}
  int call() => value;
}

const amount = Amount(1);
""",
      "shared/utilities/application/amount_fixture.dart": """
import "package:typewriter_panel/features/realms/application/amount_fixture.dart"
    as feature;

int use() {
  final a = feature.amount;
  final sum = a + a;
  final negated = -a;
  a[0] = a[1];
  final Object object = a;
  if (object case feature.Amount(:final value)) return value + sum() + negated();
  final callable = a;
  final int Function() tearOff = callable;
  return tearOff();
}
""",
    };

    // One resolution serves every case; resolving the panel barrel is slow.
    late final ModuleScan scan;
    setUpAll(() async => scan = await scanModuleFixtures(fixtures));

    test("resolves its fixtures", () => expect(scan.unresolved, isEmpty));

    test("shared code may not build a feature route", () {
      expect(
        scan.symbolsIn("shared/navigation/application/route_fixture.dart"),
        contains("OrganizationRoute"),
      );
    });

    test("authoring may not build a feature route", () {
      expect(
        scan.symbolsIn("authoring/application/route_fixture.dart"),
        contains("OrganizationRoute"),
      );
    });

    test("features may build routes", () {
      expect(
        scan.symbolsIn("features/realms/application/route_fixture.dart"),
        isEmpty,
      );
    });

    test("shared editors may not read the selection", () {
      expect(
        scan.symbolsIn("shared/editors/application/selection_fixture.dart"),
        contains("selectionProvider"),
      );
    });

    test("operators, indexes, pattern fields and implicit calls count", () {
      expect(
        scan.symbolsIn("shared/utilities/application/amount_fixture.dart"),
        containsAll(["+", "unary-", "[]", "[]=", "value", "call"]),
      );
    });
  });
}
