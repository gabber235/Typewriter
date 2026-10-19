import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Creates resources of one definition in the selected Realm.
///
/// Shortcuts, buttons, and empty states share [watchResourceCreation] so they
/// follow one enablement rule. Each invocation rereads the current scope and
/// template, so a catalog change between build and invocation is respected.
extension ResourceCreationActions on WidgetRef {
  /// Watches creation availability for [definition].
  ///
  /// Returns null while creation is unavailable.
  Future<void> Function()? watchResourceCreation(
    BuildContext context,
    skir.ResourceDefinitionId definition,
  ) => watch(selectedResourceCreationTemplateProvider(definition)) == null
      ? null
      : () => createSelectedResource(context: context, definition: definition);

  /// Creates [definition] in the selected Realm and reveals the new resource.
  ///
  /// [supplied] derives initial field values from the current document and
  /// creation template.
  Future<void> createSelectedResource({
    required BuildContext context,
    required skir.ResourceDefinitionId definition,
    CreationContext? creationContext,
    List<skir.FieldValue> Function(
      AuthoringDocument document,
      ResourceCreationTemplate template,
    )?
    supplied,
  }) async {
    final scope = read(selectedAuthoringScopeProvider);
    final document = read(selectedWorkingAuthoringDocumentProvider).value;
    final template = read(selectedResourceCreationTemplateProvider(definition));
    if (scope == null || document == null || template == null) {
      throw StateError("Resource creation is unavailable");
    }
    await read(resourceCreationProvider(scope)).createAndReveal(
      context: context,
      creationContext: creationContext,
      request: ResourceCreationRequest(
        definition: template.definition,
        configuration: template.configuration,
        supplied: supplied?.call(document, template) ?? const [],
      ),
    );
  }
}
