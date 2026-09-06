import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

final class RealmServiceAddress {
  const RealmServiceAddress({
    required this.organizationId,
    required this.realmId,
  });

  final skir.RecordId organizationId;
  final skir.RecordId realmId;

  String request(String operation) =>
      "service.to.${realmId.id}.organization.${organizationId.id}.realm.$operation";

  String event(String operation) =>
      "service.from.${realmId.id}.organization.${organizationId.id}.realm.$operation";
}
