import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/organization.dart";
import "package:typewriter_panel/infrastructure/messaging/api_exception.dart";
import "package:typewriter_panel/infrastructure/messaging/nats.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/shared/ui/components/secret_field.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

part "join_codes.freezed.dart";
part "join_codes.g.dart";

@freezed
abstract class OrganizationJoinCode with _$OrganizationJoinCode {
  const factory OrganizationJoinCode({
    required skir.RecordId code,
    required DateTime createdAt,
    DateTime? expiresAt,
    @Default(true) bool singleUse,
    @Default(JoinCodeAutoAccept()) JoinCodeAutoAccept autoAccept,
  }) = _OrganizationJoinCode;

  const OrganizationJoinCode._();

  factory OrganizationJoinCode.fromSkir(skir.JoinCode request) =>
      OrganizationJoinCode(
        code: request.code,
        createdAt: request.createdAt,
        expiresAt: request.expiresAt,
        singleUse: request.singleUse,
        autoAccept: JoinCodeAutoAccept.fromSkir(request.autoAccept),
      );

  skir.JoinCode toSkir() => skir.JoinCode(
    code: code,
    createdAt: createdAt,
    expiresAt: expiresAt,
    singleUse: singleUse,
    autoAccept: autoAccept.toSkir(),
  );

  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return remainingDuration == Duration.zero;
  }

  bool get neverExpires => expiresAt == null;
}

/// Auto-accept configuration for a join code.
@freezed
abstract class JoinCodeAutoAccept with _$JoinCodeAutoAccept {
  const factory JoinCodeAutoAccept({@Default([]) List<skir.RecordId> roleIds}) =
      _JoinCodeAutoAccept;

  const JoinCodeAutoAccept._();

  factory JoinCodeAutoAccept.fromSkir(skir.JoinCode_AutoAccept request) =>
      JoinCodeAutoAccept(roleIds: request.roleIds.toList());

  skir.JoinCode_AutoAccept toSkir() =>
      skir.JoinCode_AutoAccept(roleIds: roleIds);
}

/// Expiration configuration for generating a join code.
@freezed
sealed class JoinCodeExpiration with _$JoinCodeExpiration {
  const factory JoinCodeExpiration.never() = JoinCodeExpirationNever;
  const factory JoinCodeExpiration.duration(Duration duration) =
      JoinCodeExpirationDuration;
}

/// Options for generating a join code.
@freezed
abstract class JoinCodeOptions with _$JoinCodeOptions {
  const factory JoinCodeOptions({
    @Default(true) bool singleUse,
    @Default(JoinCodeExpiration.duration(Duration(days: 7)))
    JoinCodeExpiration expiration,
    @Default([]) List<skir.RecordId> autoAcceptRoleIds,
  }) = _JoinCodeOptions;
}

/// Provider for the join codes in the current organization.
@riverpod
class OrganizationJoinCodes extends _$OrganizationJoinCodes {
  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }
    final organizationId = ref.watch(organizationIdProvider);
    if (organizationId == null) {
      yield [];
      return;
    }

    final request = skir.WatchOrganizationJoinCodesRequest();
    yield* ref.watchRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.watch",
      listenSubject:
          "cloud.from.organization.${organizationId.id}.members.join_codes.watch",
      requestBytes: skir.WatchOrganizationJoinCodesRequest.serializer.toBytes(
        request,
      ),
      serializer: skir.WatchOrganizationJoinCodesResponse.serializer,
      transformer: (previous, response) {
        switch (response) {
          case skir.WatchOrganizationJoinCodesResponse_unknown():
            throw ApiException.unknownResponseMessage();
          case skir.WatchOrganizationJoinCodesResponse_internalErrorWrapper():
            throw ApiException.internalServerError();
          case skir.WatchOrganizationJoinCodesResponse_listWrapper(
            :final value,
          ):
            return value.map(OrganizationJoinCode.fromSkir).toList();
          case skir.WatchOrganizationJoinCodesResponse_addWrapper(:final value):
            return previous.upsertByKey(
              (code) => code.code,
              OrganizationJoinCode.fromSkir(value),
            );
          case skir.WatchOrganizationJoinCodesResponse_removeWrapper(
            :final value,
          ):
            return previous?.where((code) => code.code != value).toList() ?? [];
        }
      },
    );
  }

  /// Generates an join code for the current organization.
  Future<SecretFieldRevealed> generateCode({
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

    final response = await ref.requestSkir(
      "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.generate",
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

  /// Revokes a join code.
  Future<void> revokeCode(skir.RecordId codeId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    state.ensureReady();
    final previousState = state;

    // Optimistically remove the code
    state = AsyncValue.data(
      state.requireValue.where((c) => c.code != codeId).toList(),
    );

    try {
      final request = skir.RevokeOrganizationJoinCodeRequest(codeId: codeId);

      final response = await ref.requestSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.revoke",
        skir.RevokeOrganizationJoinCodeRequest.serializer.toBytes(request),
        skir.RevokeOrganizationJoinCodeResponse.serializer,
      );

      switch (response) {
        case skir.RevokeOrganizationJoinCodeResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.RevokeOrganizationJoinCodeResponse_codeNotFoundErrorWrapper():
          throw ApiException.notFound("Join Code");
        case skir.RevokeOrganizationJoinCodeResponse_successWrapper():
          debugPrint("Join code $codeId revoked successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }
}

/// Provider for the count of active join codes.
@riverpod
int joinCodeCount(Ref ref) {
  final codes = ref.watch(organizationJoinCodesProvider);
  return codes.maybeWhen(
    data: (data) => data.where((code) => !code.isExpired).length,
    orElse: () => 0,
  );
}
