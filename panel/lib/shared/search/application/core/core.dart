/// Application contracts for query ownership, source composition, and commands.
///
/// A [SearchSource] produces snapshots. [SourceController] owns the parsed
/// query sent to that source. [SearchController] adds selection, preview,
/// section, and command state for the search presentation layer.
library;

export "controller/controller.dart";
export "models.dart";
export "search_controller.dart";
export "search_interaction.dart";
export "search_refresher.dart";
export "search_source.dart";
export "source/source.dart";
