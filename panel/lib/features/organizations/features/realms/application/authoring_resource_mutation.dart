import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension AuthoringResourceMutation on Ref {
  Future<TypedMutationResult> updateAuthoringResource({
    required skir.ResourceId id,
    required DataValue expected,
    required DataValue proposed,
    required String label,
  }) async {
    final session = readAuthoringSession();
    final resource = session.state.resources[id];
    final revision = session.state.sequence;
    if (resource == null || revision == null) {
      throw ApiException.notFound(label);
    }
    final catalog = read(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final codec = TypedAuthoringCodec(catalog);
    final content = codec.decodeResourceOrThrow(resource).content;
    final owners = EditorOwnerRegistry(
      workspace: read(localWorkControllerProvider),
    );
    try {
      final owner = owners.editor(
        ResourceEditorTarget(
          targetId: id,
          label: label,
          resource: TypedAuthoringEditorResource(
            read(resourceRepositoriesProvider).authoring(
              session.notifier.organizationId,
              session.notifier.realmId,
            ),
            id,
          ),
          snapshot: TypedAuthoringEditorSnapshot(
            resource: resource,
            content: content,
            revision: revision,
            codec: codec,
          ),
        ),
      );
      return await owner.applyChanges(editorValueChanges(expected, proposed));
    } finally {
      owners.dispose();
    }
  }
}
