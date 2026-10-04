import "package:typewriter_panel/features/organizations/features/realms/application/realm_service_address.dart";
import "package:typewriter_panel/infrastructure/messaging/bounded_transfer_assembler.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final class RealmEditorCatalogRoute {
  const RealmEditorCatalogRoute({
    required this.organizationId,
    required this.realmId,
  });

  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  RealmServiceAddress get address =>
      RealmServiceAddress(organizationId: organizationId, realmId: realmId);

  String get fetchSubject => address.request("editor.catalog.fetch");

  String fetchUpdateSubject(String transferId) => boundedTransferUpdateSubject(
    address.event("editor.catalog.fetch"),
    transferId,
  );

  String get invalidationRequestSubject =>
      address.request("editor.catalog.invalidate");

  String get invalidationSubject => address.event("editor.catalog.invalidate");
}
