import "package:analyzer/dart/analysis/utilities.dart";
import "package:analyzer/dart/ast/ast.dart" as ast;
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../architecture/module_graph.dart";

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

/// The relative imports in [source] that are not part of a conditional
/// import. A file that is itself a conditional import target is a platform
/// stub and may import its interface relatively.
Iterable<String> relativeImports(
  String source, {
  required bool conditionalTarget,
}) {
  if (conditionalTarget) return const [];
  return parseString(content: source).unit.directives
      .whereType<ast.ImportDirective>()
      .where(
        (directive) =>
            directive.configurations.isEmpty &&
            _isRelative(directive.uri.stringValue!),
      )
      .map((directive) => directive.uri.stringValue!);
}

bool _isRelative(String uri) => Uri.parse(uri).scheme.isEmpty;

/// The files that conditional imports and exports in lib/ select between.
Set<String> conditionalTargets() => {
  for (final file in dartFiles("lib"))
    for (final directive in parseString(
      content: file.readAsStringSync(),
    ).unit.directives.whereType<ast.NamespaceDirective>())
      if (directive.configurations.isNotEmpty)
        for (final uri in [
          directive.uri.stringValue!,
          for (final configuration in directive.configurations)
            configuration.uri.stringValue!,
        ])
          ?_resolve(file, uri),
};

/// The lib/ relative path [uri] names from [file], or null outside the panel.
String? _resolve(File file, String uri) {
  final parsed = Uri.parse(uri);
  if (parsed.scheme == "package" &&
      parsed.pathSegments.first == "typewriter_panel") {
    return "lib/${parsed.pathSegments.skip(1).join("/")}";
  }
  if (parsed.scheme.isNotEmpty) return null;
  return Uri.file(file.path).resolveUri(parsed).toFilePath();
}

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

  test("relative imports are allowed only in conditional imports", () {
    expect(relativeImports('import "../x.dart";', conditionalTarget: false), [
      "../x.dart",
    ]);
    expect(relativeImports('import "x.dart";', conditionalTarget: false), [
      "x.dart",
    ]);
    expect(
      relativeImports(
        'import "x_stub.dart" if (dart.library.js_interop) "x_web.dart";',
        conditionalTarget: false,
      ),
      isEmpty,
    );
    expect(
      relativeImports('import "x.dart";', conditionalTarget: true),
      isEmpty,
    );
    expect(
      relativeImports(
        'import "package:typewriter_panel/typewriter_panel.dart";',
        conditionalTarget: false,
      ),
      isEmpty,
    );
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

  test("shared editor widgets do not read selection providers", () {
    for (final file in dartFiles("lib/shared/editors")) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains("selectionProvider")), reason: file.path);
      expect(source, isNot(contains("selectedProvider")), reason: file.path);
    }
  });
}
