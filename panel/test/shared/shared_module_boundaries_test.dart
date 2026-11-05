import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/architecture.dart";

final disallowedSharedPackageImport = RegExp(
  r'import "package:typewriter_panel/(?!typewriter_panel\.dart";|infrastructure/protocols/skir/skir\.dart"\s+as skir;)',
);

/// Libraries that own direct imports of the generated protocol tree: the Skir
/// library, which imports it relatively beside its exports, and the Skir
/// operation runtime it exports. The dependency library is a barrel and needs
/// no exemption.
const libraryBoundaries = {
  "lib/infrastructure/protocols/skir/skir.dart",
  "lib/infrastructure/protocols/operations/portable_operation_runtime.dart",
};

void main() {
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

  test("panel files import panel libraries by package", () {
    final targets = conditionalTargets();
    expect(
      targets,
      contains(
        "lib/shared/mutations/presentation/work_session_unload_protection_stub.dart",
      ),
    );
    for (final file in dartFiles("lib").where(
      (file) =>
          !isGeneratedOrBarrel(file.path) &&
          !libraryBoundaries.contains(file.path),
    )) {
      expect(
        relativeImports(
          file.readAsStringSync(),
          conditionalTarget: targets.contains(file.path),
        ),
        isEmpty,
        reason: file.path,
      );
    }
  });
}
