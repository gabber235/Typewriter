import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/api/organization/member.pb.dart"
    as member_api;
import "package:typewriter_panel/generated/api/user/organization.pb.dart";
import "package:typewriter_panel/generated/models/organization.pb.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/members.dart";
import "package:typewriter_panel/logic/proto/api_exception.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/secret_field.dart";

part "organization.g.dart";

@riverpod
class Organizations extends _$Organizations {
  @override
  Future<List<OrganizationData>> build() async {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      return [];
    }

    final request = ListOrganizationsRequest();
    final response = await ref
        .watch(natsProvider)
        .requestProto(
          "cloud.out.user.$userId.organization.list",
          request,
          ListOrganizationsResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    return response.organizations.organizations.toList();
  }

  /// Creates a new organization and returns its ID
  ///
  /// [name] The name of the organization
  /// [iconUrl] The URL of the organization's icon
  ///
  /// Returns the ID of the created organization
  Future<String?> createOrganization({
    required String name,
    required String iconUrl,
  }) async {
    state.ensureReady();

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    final request = CreateOrganizationRequest()
      ..name = name
      ..iconUrl = iconUrl;

    debugPrint("Creating organization with name: $name and iconUrl: $iconUrl");

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "cloud.out.user.$userId.organization.create",
          request,
          CreateOrganizationResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    assert(
      response.hasOrganization(),
      "When creating an organization, we didn't have an error but also didn't receive an organization",
    );

    debugPrint("Organization created with ID: ${response.organization.id}");

    // Use response data to update state directly instead of invalidating
    final newOrganization = response.organization;
    state = AsyncValue.data([...state.value!, newOrganization]);

    return newOrganization.id;
  }
}

@riverpod
String? organizationId(Ref ref) {
  return ref.watch(routeParamProvider("organizationId"));
}

@riverpod
class Organization extends _$Organization {
  @override
  Future<OrganizationData?> build() async {
    final id = ref.watch(organizationIdProvider);
    if (id == null) {
      return null;
    }
    final organizations = await ref.watch(organizationsProvider.future);
    return organizations.firstWhereOrNull((org) => org.id == id);
  }

  /// Generates an invite link (join code) for the current organization.
  Future<SecretFieldRevealed> generateInviteLink() async {
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    final request = member_api.GenerateJoinCodeRequest();

    final response = await ref
        .read(natsProvider)
        .requestProto(
          "cloud.out.user.$userId.organization.$organizationId.members.join_codes.generate",
          request,
          member_api.GenerateJoinCodeResponse.new,
        );

    if (response.hasError()) {
      throw ApiException.fromProto(response.error);
    }

    // Invalidate join codes provider so the new code appears in the list
    ref.invalidate(organizationJoinCodesProvider);

    final joinCode = response.joinCode;
    return SecretFieldRevealed(
      value: joinCode.code,
      expiresAt: joinCode.expiresAt.toDateTime(),
    );
  }
}

/// Generates an icon URL for an organization using the provided seed
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/avif?seed=$seed";
}
