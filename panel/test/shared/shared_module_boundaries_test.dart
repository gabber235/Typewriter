import "dart:io";

import "package:flutter_test/flutter_test.dart";

final disallowedSharedPackageImport = RegExp(
  r'import "package:typewriter_panel/(?!typewriter_panel\.dart|infrastructure/protocols/skir/skirout/)',
);

Iterable<File> dartFiles(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith(".dart"));
}

void expectSharedImports(String path) {
  for (final file in dartFiles(path)) {
    final source = file.readAsStringSync();
    expect(
      source,
      isNot(matches(disallowedSharedPackageImport)),
      reason: file.path,
    );
    expect(
      source,
      isNot(contains("package:typewriter_panel/features/")),
      reason: file.path,
    );
  }
}

void main() {
  test("shared imports allow only the main barrel and generated schemas", () {
    expect(
      'import "package:typewriter_panel/typewriter_panel.dart";',
      isNot(matches(disallowedSharedPackageImport)),
    );
    expect(
      'import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart";',
      isNot(matches(disallowedSharedPackageImport)),
    );
    expect(
      'import "package:typewriter_panel/features/organizations/organizations.dart";',
      matches(disallowedSharedPackageImport),
    );
    expect(
      'import "package:typewriter_panel/infrastructure/messaging/messaging.dart";',
      matches(disallowedSharedPackageImport),
    );
  });

  test("shared module imports preserve feature boundaries", () {
    expectSharedImports("lib/shared/selectables");
    expectSharedImports("lib/shared/editors");
    expectSharedImports("lib/shared/inspector");
    expectSharedImports("lib/shared/interaction_mode");
  });

  test("shared editor widgets do not read selection providers", () {
    for (final file in dartFiles("lib/shared/editors")) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains("selectionProvider")), reason: file.path);
      expect(source, isNot(contains("selectedProvider")), reason: file.path);
    }
  });
}
