import "package:collection/collection.dart";
import "package:fixnum/fixnum.dart";
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
  Stream<List<OrganizationData>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    final request = ListOrganizationsRequest();
    final stream = ref.requestProtoThenListen(
      subject: "cloud.out.user.$userId.organization.list",
      listenSubject: "cloud.in.user.$userId.organization.list",
      request: request,
      responseBuilder: ListOrganizationsResponse.new,
    );

    await for (final response in stream) {
      if (response.hasError()) {
        throw ApiException.fromProto(response.error);
      }

      yield response.organizations.organizations.toList();
    }
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

    debugPrint(
      "Organization created with ID: ${response.organization.organizationId}",
    );

    final newOrganization = response.organization;
    state = AsyncValue.data([...state.requireValue, newOrganization]);

    return newOrganization.organizationId;
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
    return organizations.firstWhereOrNull((org) => org.organizationId == id);
  }

  /// Generates an invite link (join code) for the current organization.
  Future<SecretFieldRevealed> generateInviteLink({
    JoinCodeOptions options = const JoinCodeOptions(),
  }) async {
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    final request = member_api.GenerateJoinCodeRequest()
      ..singleUse = options.singleUse;

    final expiration = member_api.JoinCodeExpiration();
    switch (options.expiration) {
      case JoinCodeExpirationNever():
        expiration.never = true;
      case JoinCodeExpirationDuration(:final duration):
        expiration.durationSeconds = Int64(duration.inSeconds);
    }
    request.expiration = expiration;

    if (options.autoAcceptRoleIds != null &&
        options.autoAcceptRoleIds!.isNotEmpty) {
      final autoAccept = member_api.JoinCodeAutoAcceptConfig()
        ..roleIds.addAll(options.autoAcceptRoleIds!);
      request.autoAccept = autoAccept;
    }

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

    final joinCode = response.joinCode;
    return SecretFieldRevealed(
      value: joinCode.code,
      expiresAt: joinCode.hasExpiresAt()
          ? joinCode.expiresAt.toDateTime()
          : null,
    );
  }
}

/// Generates an icon URL for an organization using the provided seed
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/webp?seed=$seed";
}
