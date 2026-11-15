import "package:typewriter_panel/typewriter_panel.dart";

part "organization_footprint.freezed.dart";
part "organization_footprint.g.dart";

/// What deleting the open organization takes with it, counted live.
///
/// Members lose access; services are unbound and keep running with their
/// realms; join codes stop working; roles go. The schema decides each of
/// these when the organization is deleted.
@freezed
abstract class OrganizationFootprint with _$OrganizationFootprint {
  const factory OrganizationFootprint({
    required int members,
    required int services,
    required int joinCodes,
    required int roles,
  }) = _OrganizationFootprint;
}

/// The live footprint of the open organization, or null until every count
/// has arrived.
@riverpod
OrganizationFootprint? organizationFootprint(Ref ref) {
  final organization = ref.watch(organizationIdProvider);
  if (organization == null) return null;
  final members = ref.watch(organizationMembersProvider).value;
  final services = ref
      .watch(canonicalOrganizationServicesProvider(organization))
      .value;
  final joinCodes = ref.watch(organizationJoinCodesProvider).value;
  final roles = ref.watch(organizationRolesProvider).value;
  if (members == null ||
      services == null ||
      joinCodes == null ||
      roles == null) {
    return null;
  }
  return OrganizationFootprint(
    members: members.length,
    services: services.length,
    joinCodes: joinCodes.length,
    roles: roles.length,
  );
}
