import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_appearance_provider.g.dart";

/// Name, accent and icon of one resource from its most specific declared
/// display, in the working observation of [scope].
///
/// Selects only the resource record and the catalog, so edits to other
/// resources do not recompute it. A missing resource has no appearance;
/// callers render their own missing state instead of a raw id.
@riverpod
ResourceAppearance? resourceAppearance(
  Ref ref,
  AuthoringScope scope,
  skir.ResourceId id,
) {
  final document = workingAuthoringDocumentProvider(scope);
  final record = ref.watch(
    document.select((value) => value.value?.resource(id)),
  );
  final catalog = ref.watch(document.select((value) => value.value?.catalog));
  if (record == null || catalog == null) return null;
  return catalog.appearanceOf(record);
}
