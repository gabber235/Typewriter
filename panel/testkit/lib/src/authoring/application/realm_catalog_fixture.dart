import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/catalog_fixture.dart";

final realmFixtureGeneration = skir.CatalogGeneration(value: "fixture");

skir.EditorCatalog receivedEditorCatalog({
  skir.CatalogGeneration? generation,
}) => testCatalogSnapshot(generation: generation ?? realmFixtureGeneration);

CheckedEditorCatalog receivedCheckedEditorCatalog({
  skir.CatalogGeneration? generation,
}) => CheckedEditorCatalog(receivedEditorCatalog(generation: generation));
