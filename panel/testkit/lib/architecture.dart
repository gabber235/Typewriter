/// The panel's module layering and the analyzer scans that check it, for the
/// architecture tests. Reads the panel's lib/ folder from the working
/// directory, so it runs only under `flutter test` in the panel.
library;

export "src/support/architecture/imports.dart";
export "src/support/architecture/module_graph.dart";
export "src/support/architecture/module_scan.dart";
