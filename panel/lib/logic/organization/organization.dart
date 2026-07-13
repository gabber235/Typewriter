import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.dart";
import "package:typewriter_panel/logic/api_exception.dart";
import "package:typewriter_panel/logic/auth.dart";
import "package:typewriter_panel/logic/nats.dart";
import "package:typewriter_panel/logic/organization/members.dart";
import "package:typewriter_panel/skir.dart" as skir;
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/skir.dart";
import "package:typewriter_panel/widgets/generic/components/secret_field.dart";

part "organization.freezed.dart";
part "organization.g.dart";

@freezed
abstract class OrganizationData with _$OrganizationData {
  const factory OrganizationData({
    required skir.RecordId organizationId,
    required String name,
    required String logoUrl,
  }) = _OrganizationData;

  const OrganizationData._();

  factory OrganizationData.fromSkir(skir.Organization org) {
    return OrganizationData(
      organizationId: org.organizationId,
      name: org.name,
      logoUrl: org.logoUrl,
    );
  }

  skir.Organization toSkir() {
    return skir.Organization(
      organizationId: this.organizationId,
      name: name,
      logoUrl: logoUrl,
    );
  }
}

@riverpod
class Organizations extends _$Organizations {
  @override
  Stream<List<OrganizationData>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    yield* ref.watchRequest(
      subject: "cloud.to.user.$userId.organization.watch",
      listenSubject: "cloud.from.user.$userId.organization.watch",
      requestBytes: skir.WatchUserOrganizationsRequest.serializer.toBytes(
        skir.WatchUserOrganizationsRequest(),
      ),
      serializer: skir.WatchUserOrganizationsResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchUserOrganizationsResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchUserOrganizationsResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchUserOrganizationsResponse_listWrapper(:final value):
            return value.map(OrganizationData.fromSkir).toList();
          case skir.WatchUserOrganizationsResponse_addWrapper(:final value):
            return [...?previous, OrganizationData.fromSkir(value)];
          case skir.WatchUserOrganizationsResponse_removeWrapper(:final value):
            return previous
                    ?.where((org) => org.organizationId != value)
                    .toList() ??
                [];
        }
      },
    );
  }

  /// Creates a new organization and returns its ID
  ///
  /// [name] The name of the organization
  /// [logoUrl] The URL of the organization's logo
  ///
  /// Returns the ID of the created organization
  Future<skir.RecordId> createOrganization({
    required String name,
    required String logoUrl,
  }) async {
    state.ensureReady();

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    final request = skir.CreateOrganizationRequest(
      name: name,
      logoUrl: logoUrl,
    );

    debugPrint(
      "Creating organization with name: '$name' and logoUrl: '$logoUrl'",
    );

    final response = await ref
        .read(natsProvider)
        .requestSkir(
          "cloud.to.user.$userId.organization.create",
          skir.CreateOrganizationRequest.serializer.toBytes(request),
          skir.CreateOrganizationResponse.serializer,
        );

    switch (response) {
      case skir.CreateOrganizationResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.CreateOrganizationResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.CreateOrganizationResponse_successWrapper(:final value):
        state = AsyncValue.data([
          ...state.requireValue,
          OrganizationData.fromSkir(value),
        ]);
        return value.organizationId;
    }
  }
}

@riverpod
skir.RecordId? organizationId(Ref ref) {
  final id = ref.watch(routeParamProvider("organizationId"));
  if (id == null) return null;
  return recordId("organization:$id");
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
  Future<SecretFieldRevealed> generateJoinCode({
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

    final request = skir.GenerateOrganizationJoinCodeRequest(
      singleUse: options.singleUse,
      expiration: switch (options.expiration) {
        JoinCodeExpirationNever() =>
          skir.GenerateOrganizationJoinCodeRequest_Expiration.never,
        JoinCodeExpirationDuration(:final duration) =>
          skir.GenerateOrganizationJoinCodeRequest_Expiration.createDuration(
            milliseconds: duration.inMilliseconds,
          ),
      },
      autoAccept: skir.GenerateOrganizationJoinCodeRequest_AutoAccept(
        roleIds: options.autoAcceptRoleIds,
      ),
    );

    final response = await ref
        .read(natsProvider)
        .requestSkir(
          "cloud.to.user.$userId.organization.$organizationId.members.join_codes.generate",
          skir.GenerateOrganizationJoinCodeRequest.serializer.toBytes(request),
          skir.GenerateOrganizationJoinCodeResponse.serializer,
        );

    switch (response) {
      case skir.GenerateOrganizationJoinCodeResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.GenerateOrganizationJoinCodeResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotFoundErrorWrapper():
        throw ApiException.notFound("Roles");
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotAssignableErrorWrapper():
        throw ApiException.badRequest("One or more roles cannot be assigned");
      case skir.GenerateOrganizationJoinCodeResponse_invalidExpirationErrorWrapper():
        throw ApiException.badRequest("Expiration duration must be positive");
      case skir.GenerateOrganizationJoinCodeResponse_successWrapper(
        :final value,
      ):
        return SecretFieldRevealed(
          value: value.code.id,
          expiresAt: value.expiresAt,
        );
    }
  }
}

/// Generates an icon URL for an organization using the provided seed
String generateOrganizationIconUrl(String seed) {
  return "https://api.dicebear.com/9.x/shapes/webp?seed=$seed";
}
