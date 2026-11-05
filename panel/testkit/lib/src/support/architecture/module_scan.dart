import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/diagnostic/diagnostic.dart";
import "package:analyzer/file_system/overlay_file_system.dart";
import "package:analyzer/file_system/physical_file_system.dart";
import "package:typewriter_testkit/src/support/architecture/module_graph.dart";

/// One reference from a panel file to a symbol another module declares.
final class ModuleReference {
  const ModuleReference(
    this.file,
    this.line,
    this.symbol,
    this.from,
    this.to,
    this.library,
  );

  final String file;
  final int line;
  final String symbol;
  final PanelModule from;
  final PanelModule to;

  /// The declaring library's path below lib/.
  final String library;

  /// Whether the module graph or [forbiddenLibraries] rejects this reference.
  bool get isViolation => !from.mayUse(to) || forbidsLibrary(from, library);

  @override
  String toString() =>
      "$file:$line uses $symbol ($library); ${from.path} may not depend on it";
}

/// Follows every identifier, type, operator, index, pattern field and implicit
/// `call` to the library that declares it. Generated parts resolve to their
/// declaring library, so `fooProvider` counts for the module of `foo.dart`.
final class ModuleReferenceCollector extends RecursiveAstVisitor<void> {
  ModuleReferenceCollector(this.unit, this.from);

  final ResolvedUnitResult unit;
  final PanelModule from;
  final references = <ModuleReference>[];

  void _add(AstNode node, Element? element) {
    final uri = element?.library?.uri;
    if (uri == null ||
        uri.scheme != "package" ||
        uri.pathSegments.first != "typewriter_panel") {
      return;
    }
    if (isGeneratedRoute(element!) && mayUseGeneratedRoutes(from)) return;
    final library = uri.pathSegments.skip(1).join("/");
    final to = moduleOf(library);
    if (to == from) return;
    references.add(
      ModuleReference(
        unit.path,
        unit.lineInfo.getLocation(node.offset).lineNumber,
        element.displayName,
        from,
        to,
        library,
      ),
    );
  }

  /// A compound assignment, `++` or `--` reads and writes through its target
  /// in addition to calling its operator.
  void _addCompound(CompoundAssignmentExpression node) {
    _add(node, node.readElement);
    _add(node, node.writeElement);
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

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _add(node, node.element);
    super.visitBinaryExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _add(node, node.element);
    _addCompound(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _add(node, node.element);
    _addCompound(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _add(node, node.element);
    super.visitIndexExpression(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _add(node, node.element);
    _addCompound(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _add(node, node.element);
    super.visitPatternField(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _add(node, node.element);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    _add(node, node.element);
    super.visitImplicitCallReference(node);
  }
}

/// What resolving the panel libraries found.
final class ModuleScan {
  /// The references the module graph or [forbiddenLibraries] rejects.
  final violations = <ModuleReference>[];

  /// The libraries that did not resolve, and the errors of those that did.
  final unresolved = <String>[];

  /// Every module edge a reference crossed, as from and to module paths.
  final observed = <(String, String)>{};

  /// The symbols the rejected references of the library at [libraryPath],
  /// below lib/, use.
  Iterable<String> symbolsIn(String libraryPath) => violations
      .where((violation) => violation.file.endsWith("/lib/$libraryPath"))
      .map((violation) => violation.symbol);
}

/// Resolves every library [collection] analyzes below the lib/ folder at
/// [root] and collects the references that cross modules.
Future<ModuleScan> scanModules(
  AnalysisContextCollection collection,
  String root,
) async {
  final scan = ModuleScan();
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
        scan.unresolved.add(path);
        continue;
      }
      for (final unit in library.units) {
        if (isGeneratedOrBarrel(unit.path, source: unit.content)) continue;
        final from = moduleOf(unit.path.substring(root.length + 1));
        // A file that does not resolve has null elements and would pass silently.
        scan.unresolved.addAll(
          unit.diagnostics
              .where((d) => d.severity == Severity.error)
              .map((d) => "${unit.path}: ${d.message}"),
        );
        final collector = ModuleReferenceCollector(unit, from);
        unit.unit.accept(collector);
        scan.observed.addAll(
          collector.references.map(
            (reference) => (reference.from.path, reference.to.path),
          ),
        );
        scan.violations.addAll(
          collector.references.where((reference) => reference.isViolation),
        );
      }
    }
  }
  return scan;
}

/// Resolves [sources], keyed by their library path below lib/, as if they
/// were panel libraries, without writing them to disk.
Future<ModuleScan> scanModuleFixtures(Map<String, String> sources) {
  final root = Directory("lib").absolute.path;
  final provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
  for (final MapEntry(key: path, value: source) in sources.entries) {
    provider.setOverlay("$root/$path", content: source, modificationStamp: 0);
  }
  return scanModules(
    AnalysisContextCollection(
      includedPaths: [for (final path in sources.keys) "$root/$path"],
      resourceProvider: provider,
      sdkPath: dartSdkPath(),
    ),
    root,
  );
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
