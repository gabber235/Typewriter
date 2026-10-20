import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Creates resources of one type in the selected Realm.
///
/// Shortcuts, buttons, and empty states share [watchResourceCreation] so they
/// follow one enablement rule. Each invocation rereads the current scope and
/// template, so a catalog change between build and invocation is respected.
extension ResourceCreationActions on WidgetRef {
  /// Watches creation availability for [type].
  ///
  /// Returns null while creation is unavailable.
  Future<void> Function()? watchResourceCreation(
    BuildContext context,
    skir.TypeDefinitionId type, {
    skir.ValueLocation? owner,
  }) => watch(selectedResourceCreationTemplateProvider(type)) == null
      ? null
      : () =>
            createSelectedResource(context: context, type: type, owner: owner);

  /// Creates [type] in the selected Realm and reveals the new resource.
  ///
  /// With an [owner], the new resource joins that owning link field, such as
  /// the pages of the routed Book. [supplied] holds initial field values.
  Future<void> createSelectedResource({
    required BuildContext context,
    required skir.TypeDefinitionId type,
    skir.ValueLocation? owner,
    List<skir.FieldValue> supplied = const [],
  }) async {
    final scope = read(selectedAuthoringScopeProvider);
    if (scope == null ||
        read(selectedResourceCreationTemplateProvider(type)) == null) {
      throw StateError("Resource creation is unavailable");
    }
    await read(resourceCreationProvider(scope)).createOwnedResource(
      context: context,
      type: type,
      owner: owner,
      supplied: supplied,
    );
  }
}
