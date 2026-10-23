import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("the reusable organization shell owns the inspector", () {
    final organization = File(
      "lib/features/organizations/presentation/organization_route.dart",
    ).readAsStringSync();

    expect(organization, contains("InspectorScaffold("));
    expect("InspectorScaffold(".allMatches(organization), hasLength(1));
    expect(organization, contains("OrganizationScaffold(child: AutoRouter())"));
    expect(
      organization,
      matches(RegExp(r"Expanded\(\s*child: InspectorScaffold\(")),
    );
    expect(organization, contains("child: child,"));
  });

  test("selectable route pages do not own inspectors", () {
    final paths = [
      "lib/features/services/presentation/route.dart",
      "lib/features/realms/presentation/resource_route.dart",
    ];

    for (final path in paths) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains("InspectorScaffold")),
      );
    }
  });
}
