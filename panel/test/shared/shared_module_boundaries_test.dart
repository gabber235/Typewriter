import "dart:io";

import "package:flutter_test/flutter_test.dart";

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
      isNot(contains("package:typewriter_panel/features/")),
      reason: file.path,
    );
    expect(
      source,
      isNot(
        matches(
          RegExp(
            r'import "package:typewriter_panel/(?!typewriter_panel\.dart)',
          ),
        ),
      ),
      reason: file.path,
    );
  }
}

void main() {
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
