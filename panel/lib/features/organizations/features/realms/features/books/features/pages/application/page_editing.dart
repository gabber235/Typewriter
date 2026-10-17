import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension PageEditingRef on WidgetRef {
  /// Opens the existing resource inspector without toggling an existing selection.
  void inspectPage(skir.ResourceId id) {
    final organizationId = read(organizationIdProvider);
    final realmId = read(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    read(selectionProvider.notifier).selectAll([
      AuthoringResourceIdentifier(
        organizationId: organizationId,
        realmId: realmId,
        resourceId: id,
      ),
    ]);
  }
}
