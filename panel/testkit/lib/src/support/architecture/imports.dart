import "dart:io";

import "package:analyzer/dart/analysis/utilities.dart";
import "package:analyzer/dart/ast/ast.dart" as ast;

/// The Dart files below the folder [path], recursively.
Iterable<File> dartFiles(String path) =>
    Directory(path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith(".dart"));

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
            Uri.parse(directive.uri.stringValue!).scheme.isEmpty,
      )
      .map((directive) => directive.uri.stringValue!);
}

/// The files that conditional imports and exports in lib/ select between,
/// as paths starting at lib/.
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
