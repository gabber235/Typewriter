import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The ready preview of changing the type arguments of `variable:1` to
/// [next] in [catalog], with no edit and clearing the [cleared] values.
skir.PreviewTypeArgumentChangeResponse readyTypeArgumentPreview(
  CheckedEditorCatalog catalog,
  skir.TypeSelection next, {
  List<skir.ValueLocation> cleared = const [],
}) => skir.PreviewTypeArgumentChangeResponse.createReady(
  resource: skir.ResourceId(value: "variable:1"),
  next: next,
  edit: skir.PreparedEdit(
    catalog: catalog.snapshot.generation,
    expectations: const [],
    intents: const [],
  ),
  linkRepairs: const [],
  clearedLocations: cleared,
);
