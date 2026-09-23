import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension AuthoringResourceTarget on AuthoringSessionState {
  EditorTarget authoringResourceTarget({
    required AuthoringResourceRepository repository,
    required SelectableIdentifier identity,
    required String label,
    required TypeCatalog typeCatalog,
  }) {
    final id = skir.ResourceId(value: identity.id);
    final resource = resources[id];
    if (resource == null) {
      throw StateError("The editable resource is not loaded");
    }
    final currentGeneration = generation;
    final revision = sequence;
    if (currentGeneration == null || revision == null) {
      throw StateError("The authoring catalog is not loaded");
    }
    final catalog = RealmEditorCatalogSnapshot(
      catalog: typeCatalog,
      generation: CatalogGeneration(currentGeneration.value),
    );
    final codec = TypedAuthoringCodec(catalog);
    final decoded = codec.decodeResourceOrThrow(resource);
    return ResourceEditorTarget(
      targetId: identity,
      label: label,
      resource: TypedAuthoringEditorResource(repository, id),
      snapshot: TypedAuthoringEditorSnapshot(
        resource: resource,
        content: decoded.content,
        revision: revision,
        codec: codec,
      ),
    );
  }
}
