import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../architecture/module_graph.dart";

final disallowedSharedPackageImport = RegExp(
  r'import "package:typewriter_panel/(?!typewriter_panel\.dart";|infrastructure/protocols/skir/skir\.dart"\s+as skir;)',
);

/// Libraries that own direct dependency and generated protocol imports: the
/// dependency library, the Skir library and the Skir operation runtime it
/// exports.
const libraryBoundaries = {
  "lib/dependencies.dart",
  "lib/infrastructure/protocols/skir/skir.dart",
  "lib/infrastructure/protocols/operations/portable_operation_runtime.dart",
};

Iterable<File> dartFiles(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith(".dart"));
}

void main() {
  test("shared imports allow only the main barrel and named Skir library", () {
    expect(
      'import "package:typewriter_panel/typewriter_panel.dart";',
      isNot(matches(disallowedSharedPackageImport)),
    );
    expect(
      'import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as skir;',
      isNot(matches(disallowedSharedPackageImport)),
    );
    expect(
      'import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart" as action;',
      matches(disallowedSharedPackageImport),
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

  test("panel files import only the main barrel and the skir library", () {
    for (final file in dartFiles("lib").where(
      (file) =>
          !isGeneratedOrBarrel(file.path) &&
          !libraryBoundaries.contains(file.path),
    )) {
      expect(
        file.readAsStringSync(),
        isNot(matches(disallowedSharedPackageImport)),
        reason: file.path,
      );
    }
  });

  test("shared editor widgets do not read selection providers", () {
    for (final file in dartFiles("lib/shared/editors")) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains("selectionProvider")), reason: file.path);
      expect(source, isNot(contains("selectedProvider")), reason: file.path);
    }
  });
}
