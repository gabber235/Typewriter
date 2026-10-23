import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/diagnostic/diagnostic.dart";
import "package:flutter_test/flutter_test.dart";

import "module_graph.dart";

/// One reference from a panel file to a symbol another module declares.
final class _Reference {
  const _Reference(this.file, this.line, this.symbol, this.from, this.to);

  final String file;
  final int line;
  final String symbol;
  final PanelModule from;
  final PanelModule to;

  @override
  String toString() =>
      "$file:$line uses $symbol (${to.path}); ${from.path} may not depend on ${to.path}";
}

/// Follows every identifier, type and extension member to the library that
/// declares it. Generated parts resolve to their declaring library, so
/// `fooProvider` counts for the module of `foo.dart`.
final class _ReferenceCollector extends RecursiveAstVisitor<void> {
  _ReferenceCollector(this.unit, this.from);

  final ResolvedUnitResult unit;
  final PanelModule from;
  final references = <_Reference>[];

  void _add(AstNode node, Element? element) {
    final uri = element?.library?.uri;
    if (uri == null ||
        uri.scheme != "package" ||
        uri.pathSegments.first != "typewriter_panel") {
      return;
    }
    if (isGeneratedRoute(element!)) return;
    final to = moduleOf(uri.pathSegments.skip(1).join("/"));
    if (to == from) return;
    references.add(
      _Reference(
        unit.path,
        unit.lineInfo.getLocation(node.offset).lineNumber,
        element.displayName,
        from,
        to,
      ),
    );
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _add(node, node.element);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _add(node, node.element);
    super.visitNamedType(node);
  }
}

/// The Dart SDK of the Flutter toolchain running the test. Under `flutter test`
/// the analyzer cannot derive it from Platform.resolvedExecutable (flutter_tester).
String dartSdkPath() {
  final path = "${Platform.environment["FLUTTER_ROOT"]}/bin/cache/dart-sdk";
  if (!Directory(path).existsSync()) {
    throw StateError("No Dart SDK at $path; run through flutter test");
  }
  return path;
}

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

  test("modules depend only on modules below them", () async {
    final root = Directory("lib").absolute.path;
    final collection = AnalysisContextCollection(
      includedPaths: [root],
      sdkPath: dartSdkPath(),
    );
    final violations = <_Reference>[];
    final unresolved = <String>[];
    final observed = <(String, String)>{};
    for (final context in collection.contexts) {
      final session = context.currentSession;
      for (final path in context.contextRoot.analyzedFiles().where(
        (path) => path.endsWith(".dart"),
      )) {
        // Each library is resolved once together with its parts.
        final file = session.getFile(path);
        if (file is FileResult && file.isPart) continue;
        final library = await session.getResolvedLibrary(path);
        if (library is! ResolvedLibraryResult) {
          unresolved.add(path);
          continue;
        }
        for (final unit in library.units) {
          if (isGeneratedOrBarrel(unit.path)) continue;
          final from = moduleOf(unit.path.substring(root.length + 1));
          // A file that does not resolve has null elements and would pass silently.
          unresolved.addAll(
            unit.diagnostics
                .where((d) => d.severity == Severity.error)
                .map((d) => "${unit.path}: ${d.message}"),
          );
          final collector = _ReferenceCollector(unit, from);
          unit.unit.accept(collector);
          observed.addAll(
            collector.references.map(
              (reference) => (reference.from.path, reference.to.path),
            ),
          );
          violations.addAll(
            collector.references.where(
              (reference) => !from.mayUse(reference.to),
            ),
          );
        }
      }
    }
    expect(unresolved, isEmpty);
    // Positive control: if resolution silently failed, no edge would be seen at all.
    expect(observed, contains(("shared/ui", "shared/theme")));
    expect(violations.map((violation) => "$violation"), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
