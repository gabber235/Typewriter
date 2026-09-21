import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Creates an editor target for one loaded element resource.
EditorTarget authoringElementTarget({
  required AuthoringResourceRepository repository,
  required AuthoringSessionState state,
  required SelectableIdentifier identity,
  required String label,
  required EditorDocument document,
}) {
  final id = skir.ResourceId(value: identity.id);
  final resource = state.resources[id];
  if (resource == null || resource.kind != skir.ResourceKind.element) {
    throw StateError("The editable element is not loaded");
  }
  final generation = state.generation;
  if (generation == null) {
    throw StateError("The authoring catalog is not loaded");
  }
  final catalog = RealmEditorCatalogSnapshot(
    catalog: document.typeCatalog,
    generation: CatalogGeneration(generation.value),
  );
  final codec = TypedAuthoringCodec(catalog);
  final decoded = codec.decodeResourceOrThrow(resource);
  return ResourceEditorTarget(
    targetId: identity,
    label: label,
    resource: ElementEditorResource(repository, id),
    snapshot: ElementEditorSnapshot(
      resource: resource,
      content: decoded.content,
      valueDocument: document,
      codec: codec,
    ),
  );
}

/// One element resource presented through its complete typed content.
final class ElementEditorSnapshot extends EditorSnapshot
    implements TypedAuthoringSnapshot, EditorContractSnapshot {
  const ElementEditorSnapshot({
    required this.resource,
    required this.content,
    required this.valueDocument,
    required this.codec,
  });

  final skir.AuthoringResource resource;
  final TypedValueEnvelope content;
  final EditorDocument valueDocument;
  @override
  final TypedAuthoringCodec codec;

  @override
  bool contractCompatibleWith(EditorSnapshot candidate) {
    if (candidate is! ElementEditorSnapshot ||
        candidate.content.rootType != content.rootType) {
      return false;
    }
    if (candidate.codec.catalog.generation == codec.catalog.generation) {
      return true;
    }
    return editorCatalogContractsCompatible(
      codec.catalog,
      candidate.codec.catalog,
      RealmEditorCatalogRequest(types: {content.rootType}),
    );
  }

  @override
  skir.AuthoringOperation encodePreviewCommit(EditorCommit commit) {
    final proposed = resource.toMutable()
      ..content = codec
          .encodeEnvelope(content.copyWith(rootValue: commit.rootValue))
          .valueOrNull!;
    final wire = SkirEditorCodec(codec.registry);
    return skir.AuthoringOperation.createCommit(
      id: resource.id,
      observedSequence: commit.expectedRevision,
      base: resource,
      proposed: proposed,
      changedPaths: commit.changedPaths.map(
        (path) => wire.encodePath(path).valueOrNull!,
      ),
    );
  }

  @override
  EditorDocument get document => valueDocument;
}

/// Projects and commits one generic element resource.
final class ElementEditorResource extends AuthoringEditorResource {
  const ElementEditorResource(super.repository, super.id);

  @override
  Future<EditorSnapshot?> project(skir.AuthoringGraphSnapshot snapshot) async {
    final resource = snapshot.resources
        .where((item) => item.id == id)
        .firstOrNull;
    if (resource == null) return null;
    return _snapshot(resource, snapshot.sequence, snapshot.generation);
  }

  @override
  Future<EditorSnapshot?> projectApplied(
    skir.AuthoringChanged change,
    EditorSnapshot submitted,
  ) async {
    for (final item in change.resources) {
      switch (item) {
        case skir.AuthoringResourceChange_upsertWrapper(:final value)
            when value.id == id:
          return _snapshot(value, change.sequence, change.generation);
        case skir.AuthoringResourceChange_removeWrapper(:final value)
            when value == id:
          return null;
        case skir.AuthoringResourceChange_unknown() ||
            skir.AuthoringResourceChange_upsertWrapper() ||
            skir.AuthoringResourceChange_removeWrapper():
      }
    }
    return null;
  }

  @override
  AuthoringContribution operations(
    EditorSnapshot snapshot,
    EditorCommit commit,
  ) {
    final current = snapshot as ElementEditorSnapshot;
    return (
      generation: current.codec.catalog.generation,
      operations: [current.encodePreviewCommit(commit)],
    );
  }

  Future<ElementEditorSnapshot> _snapshot(
    skir.AuthoringResource resource,
    int revision,
    skir.CatalogGeneration generation,
  ) async {
    final roots = SkirTypeCodec(TypeRegistry(const TypeCatalog([])));
    final rootType = roots
        .decodeReference(resource.content.rootType)
        .valueOrNull;
    if (rootType == null) {
      throw StateError("The element resource contract is invalid");
    }
    final catalog = await repository.fetchCatalog(
      generation,
      RealmEditorCatalogRequest(types: {rootType}),
    );
    final codec = TypedAuthoringCodec(catalog);
    final decoded = codec.decodeResourceOrThrow(resource);
    return ElementEditorSnapshot(
      resource: resource,
      content: decoded.content,
      codec: codec,
      valueDocument: EditorDocument(
        rootType: NamedType(decoded.content.rootType),
        typeCatalog: catalog.catalog,
        confirmedValue: decoded.content.rootValue,
        revision: revision,
      ),
    );
  }
}
