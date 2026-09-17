/// Application contracts for loading, decoding, projecting, and mutating page
/// elements. The page authoring session owns canonical documents. Providers in
/// this library expose decoded read models, while [PageElements] coordinates
/// edits and delegates persistence to the shared editor ownership pipeline.
library;

export "element_commands.dart";
export "element_definition.dart";
export "entries.dart";
export "page_elements.dart";
