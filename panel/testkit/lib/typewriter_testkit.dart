/// The panel test kit: one way to start the panel over composable test
/// worlds, shared by widget tests, story tests, stories and journeys.
///
/// - core: [World], [Trait] and [PanelStage].
/// - doubles: one stateful double per seam the panel reaches out through.
/// - traits: the sources and edge cases a test world is composed of.
/// - generators: seeded data for property tests and stories.
///
/// Widgetbook builds this library for the web, so it holds nothing that
/// needs a test runner; `package:typewriter_testkit/testing.dart` adds that.
library;

export "app.dart";
export "authoring.dart";
export "core.dart";
export "doubles.dart";
export "generators.dart";
export "shared.dart";
export "traits.dart";
