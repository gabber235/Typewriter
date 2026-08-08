import "dart:io";

import "package:flutter_test/flutter_test.dart";

void main() {
  test("organization and book shells own the inspector", () {
    final organization = File(
      "lib/features/organizations/presentation/organization_route.dart",
    ).readAsStringSync();
    final book = File(
      "lib/features/organizations/features/realms/features/books/presentation/book/route.dart",
    ).readAsStringSync();

    expect(organization, contains("InspectorScaffold("));
    expect(organization, contains("child: AutoRouter()"));
    expect(book, contains("InspectorScaffold("));
    expect(book, contains("child: AutoRouter("));
  });

  test("selectable route pages do not own inspectors", () {
    final paths = [
      "lib/features/organizations/features/services/presentation/route.dart",
      "lib/features/organizations/features/realms/features/tags/presentation/route.dart",
      "lib/features/organizations/features/realms/features/books/presentation/library/route.dart",
      "lib/features/organizations/features/realms/features/books/features/pages/presentation/route.dart",
    ];

    for (final path in paths) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains("InspectorScaffold")),
      );
    }
  });
}
