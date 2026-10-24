import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer/dart/ast/visitor.dart";
import "package:analyzer/dart/element/element.dart";
import "package:analyzer/diagnostic/diagnostic.dart";
import "package:analyzer/file_system/overlay_file_system.dart";
import "package:analyzer/file_system/physical_file_system.dart";
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

/// Follows every identifier, type, operator, index, pattern field and implicit
/// `call` to the library that declares it. Generated parts resolve to their
/// declaring library, so `fooProvider` counts for the module of `foo.dart`.
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
    if (isGeneratedRoute(element!) && mayUseGeneratedRoutes(from)) return;
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
final class _Scan {
  final violations = <_Reference>[];
  final unresolved = <String>[];
  final observed = <(String, String)>{};
}

/// Resolves every library [collection] analyzes below the lib/ folder at
/// [root] and collects the references that cross modules.
Future<_Scan> _scan(AnalysisContextCollection collection, String root) async {
  final scan = _Scan();
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
        final collector = _ReferenceCollector(unit, from);
        unit.unit.accept(collector);
        scan.observed.addAll(
          collector.references.map(
            (reference) => (reference.from.path, reference.to.path),
          ),
        );
        scan.violations.addAll(
          collector.references.where((reference) => !from.mayUse(reference.to)),
        );
      }
    }
  }
  return scan;
}

/// Resolves [sources], keyed by their library path below lib/, as if they
/// were panel libraries, without writing them to disk.
Future<_Scan> _scanFixtures(Map<String, String> sources) {
  final root = Directory("lib").absolute.path;
  final provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
  for (final MapEntry(key: path, value: source) in sources.entries) {
    provider.setOverlay("$root/$path", content: source, modificationStamp: 0);
  }
  return _scan(
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

  test("only the dependency library and main own root files", () {
    expect(tryModuleOf("dependencies.dart")?.path, "dependencies");
    expect(tryModuleOf("dependencies_io_stub.dart")?.path, "dependencies");
    expect(tryModuleOf("main.dart")?.path, "app");
    expect(tryModuleOf("helpers.dart"), isNull);
  });

  test("modules depend only on modules below them", () async {
    final root = Directory("lib").absolute.path;
    final scan = await _scan(
      AnalysisContextCollection(includedPaths: [root], sdkPath: dartSdkPath()),
      root,
    );
    expect(scan.unresolved, isEmpty);
    // Positive control: if resolution silently failed, no edge would be seen at all.
    expect(scan.observed, contains(("shared/ui", "shared/theme")));
    expect(scan.violations.map((violation) => "$violation"), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));

  group("the reference rule", () {
    const routeUse = """
import "package:typewriter_panel/typewriter_panel.dart";

PageRouteInfo<Object?> organizationHome() =>
    OrganizationRoute(organizationId: "organization");
""";
    const fixtures = {
      "shared/navigation/application/route_fixture.dart": routeUse,
      "authoring/application/route_fixture.dart": routeUse,
      "features/realms/application/route_fixture.dart": routeUse,
      "features/realms/application/amount_fixture.dart": """
class Amount {
  const Amount(this.value);
  final int value;
  Amount operator +(Amount other) => Amount(value + other.value);
  Amount operator -() => Amount(-value);
  int operator [](int index) => value;
  void operator []=(int index, int next) {}
  int call() => value;
}

const amount = Amount(1);
""",
      "shared/utilities/application/amount_fixture.dart": """
import "package:typewriter_panel/features/realms/application/amount_fixture.dart"
    as feature;

int use() {
  final a = feature.amount;
  final sum = a + a;
  final negated = -a;
  a[0] = a[1];
  final Object object = a;
  if (object case feature.Amount(:final value)) return value + sum() + negated();
  final callable = a;
  final int Function() tearOff = callable;
  return tearOff();
}
""",
    };

    // One resolution serves every case; resolving the panel barrel is slow.
    late final _Scan scan;
    setUpAll(() async => scan = await _scanFixtures(fixtures));

    Iterable<String> symbolsIn(String libraryPath) => scan.violations
        .where((violation) => violation.file.endsWith("/lib/$libraryPath"))
        .map((violation) => violation.symbol);

    test("resolves its fixtures", () => expect(scan.unresolved, isEmpty));

    test("shared code may not build a feature route", () {
      expect(
        symbolsIn("shared/navigation/application/route_fixture.dart"),
        contains("OrganizationRoute"),
      );
    });

    test("authoring may not build a feature route", () {
      expect(
        symbolsIn("authoring/application/route_fixture.dart"),
        contains("OrganizationRoute"),
      );
    });

    test("features may build routes", () {
      expect(
        symbolsIn("features/realms/application/route_fixture.dart"),
        isEmpty,
      );
    });

    test("operators, indexes, pattern fields and implicit calls count", () {
      expect(
        symbolsIn("shared/utilities/application/amount_fixture.dart"),
        containsAll(["+", "unary-", "[]", "[]=", "value", "call"]),
      );
    });
  });
}
