import "dart:io";

import "package:analyzer/dart/element/element.dart";

/// The panel's modules and the modules each may use directly. A module may also
/// use everything those modules may use, so this is the layering, bottom first.
/// The architecture test rejects any reference outside it and any cycle in it.
final panelModules = PanelModuleGraph({
  "dependencies": [],
  "infrastructure/protocols": ["dependencies"],
  "shared/theme": ["dependencies"],
  "shared/utilities": ["shared/theme", "infrastructure/protocols"],
  "infrastructure/observability": ["shared/utilities"],
  "shared/hooks": ["shared/utilities"],
  "shared/navigation": ["shared/utilities"],
  "shared/shortcuts": ["shared/hooks"],
  "infrastructure/session": ["shared/navigation"],
  "infrastructure/messaging": [
    "infrastructure/session",
    "infrastructure/observability",
  ],
  "shared/interaction_mode": ["shared/shortcuts"],
  "shared/ui": ["shared/interaction_mode"],
  "shared/selectables": ["shared/ui"],
  "shared/search": ["shared/selectables"],
  "shared/graph": ["shared/selectables"],
  "shared/portable": ["shared/utilities"],
  "shared/mutations": [
    "shared/ui",
    "shared/portable",
    "infrastructure/messaging",
  ],
  "shared/shell": ["shared/mutations"],
  "shared/editing": ["shared/mutations", "shared/selectables"],
  "shared/editors": ["shared/editing", "shared/search", "shared/graph"],
  "shared/inspector": ["shared/editors"],
  "authoring": ["shared/inspector"],
  "features/auth": ["shared/shell"],
  "features/services": ["shared/inspector", "shared/shell"],
  "features/members": ["shared/shell"],
  "features/realms": ["authoring", "features/services"],
  "features/organizations": ["features/realms", "features/members"],
  "app": ["features/auth", "features/organizations"],
});

/// The one accepted upward reference: auto_route generates typed route classes
/// (`OrganizationRoute`, `ServicesRoute`) and their named arguments into
/// app_router.gr.dart, and features navigate with them. The router in turn
/// builds the feature pages. Matched by the declaring file, so a route's
/// constructor parameters count too. Only the app and the features may use
/// them; shared code and authoring receive routes from a feature instead.
bool isGeneratedRoute(Element element) =>
    element.firstFragment.libraryFragment?.source.uri.path.endsWith(
      ".gr.dart",
    ) ??
    false;

/// Whether code in [module] may use the generated routes, which the app
/// module declares.
bool mayUseGeneratedRoutes(PanelModule module) =>
    module.path == "app" || module.path.startsWith("features/");

/// One declared module: a folder below lib/, owning every file beneath it
/// that no deeper module claims.
final class PanelModule {
  PanelModule._(this.path, this._graph);

  final String path;
  final PanelModuleGraph _graph;

  /// Whether code in this module may use [other]: itself or anything below.
  bool mayUse(PanelModule other) =>
      other == this || _graph.below(this).contains(other);
}

final class PanelModuleGraph {
  PanelModuleGraph(Map<String, List<String>> uses)
    : _uses = uses.map((path, used) => MapEntry(path, used.toSet())) {
    for (final path in uses.keys) {
      _modules[path] = PanelModule._(path, this);
    }
  }

  final Map<String, Set<String>> _uses;
  final _modules = <String, PanelModule>{};
  final _below = <PanelModule, Set<PanelModule>>{};

  Iterable<PanelModule> get modules => _modules.values;

  Set<PanelModule> directlyUsed(PanelModule module) => {
    for (final path in _uses[module.path]!) _modules[path]!,
  };

  /// Every module reachable from [module], memoized.
  Set<PanelModule> below(PanelModule module) => _below.putIfAbsent(module, () {
    final reached = <PanelModule>{};
    final pending = [...directlyUsed(module)];
    while (pending.isNotEmpty) {
      final next = pending.removeLast();
      if (reached.add(next)) pending.addAll(directlyUsed(next));
    }
    return reached;
  });

  /// The deepest declared module whose folder contains [libraryPath], or null.
  PanelModule? tryModuleOf(String libraryPath) {
    if (!libraryPath.contains("/")) {
      final owner = _rootFiles[libraryPath];
      return owner == null ? null : _modules[owner];
    }
    final owners = _modules.keys.where(
      (path) => libraryPath.startsWith("$path/"),
    );
    if (owners.isEmpty) return null;
    return _modules[owners.reduce((a, b) => a.length >= b.length ? a : b)];
  }
}

/// The files directly below lib/ that belong to a module. Any other root file
/// belongs to no module, so the architecture test reports it.
const _rootFiles = {
  "main.dart": "app",
  "dependencies.dart": "dependencies",
  "dependencies_io_stub.dart": "dependencies",
};

PanelModule moduleOf(String libraryPath) =>
    panelModules.tryModuleOf(libraryPath) ??
    (throw StateError("$libraryPath belongs to no declared module"));

PanelModule? tryModuleOf(String libraryPath) =>
    panelModules.tryModuleOf(libraryPath);

/// Modules that can reach themselves; empty for a valid graph.
List<String> cyclesIn(PanelModuleGraph graph) => [
  for (final module in graph.modules)
    if (graph.below(module).contains(module)) module.path,
];

/// Generated files belong to their declaring library; a barrel holds only
/// directives (library, import, export, part), whatever its name. [source]
/// defaults to the file's content on disk.
bool isGeneratedOrBarrel(String path, {String? source}) =>
    path.endsWith(".g.dart") ||
    path.endsWith(".freezed.dart") ||
    path.endsWith(".gr.dart") ||
    path.contains("/skirout/") ||
    _onlyDirectives(source ?? File(path).readAsStringSync());

final _comment = RegExp(r"//[^\n]*|/\*[\s\S]*?\*/");
final _directive = RegExp(
  r"^\s*(library|import|export|part)\b[^;]*;",
  multiLine: true,
);

bool _onlyDirectives(String source) =>
    source.replaceAll(_comment, "").replaceAll(_directive, "").trim().isEmpty;
