import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/generated/api/organization.pb.dart";
import "package:typewriter_panel/generated/models/organization.pb.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/utils/riverpod.dart";

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

    return response.organizations.toList();
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
      throw Exception("User not found");
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
      throw Exception(
        "Failed to create organization: ${response.error.message}",
      );
    }

    assert(
      response.hasOrganization(),
      "When creating an organization, we didn't have an error but also didn't receive an organization",
    );

    debugPrint("Organization created with ID: ${response.organization.id}");

    ref.invalidateSelf();
    return response.organization.id;
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
}

/// Generates an icon URL for an organization using the provided seed
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/avif?seed=$seed";
}
