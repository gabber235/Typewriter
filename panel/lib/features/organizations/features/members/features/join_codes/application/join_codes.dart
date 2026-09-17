import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "join_codes.freezed.dart";
part "join_codes.g.dart";

/// The organization owned invitation projection shown in the member management UI.
///
/// The service owns creation, expiration, consumption, and revocation. This
/// value is the panel read model, translated at the Skir boundary and updated
/// from the initial snapshot plus sequenced changes. A null [expiresAt] is the
/// explicit never expires state, not an unknown timestamp.
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

  /// Converts the service projection into the immutable panel read model.
  factory OrganizationJoinCode.fromSkir(skir.JoinCode request) =>
      OrganizationJoinCode(
        code: request.code,
        createdAt: request.createdAt,
        expiresAt: request.expiresAt,
        singleUse: request.singleUse,
        autoAccept: JoinCodeAutoAccept.fromSkir(request.autoAccept),
      );

  /// Converts this read model back to the protocol shape for shared consumers.
  skir.JoinCode toSkir() => skir.JoinCode(
    code: code,
    createdAt: createdAt,
    expiresAt: expiresAt,
    singleUse: singleUse,
    autoAccept: autoAccept.toSkir(),
  );

  /// Time remaining at read time, clamped to zero after expiration.
  Duration? get remainingDuration {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether the service timestamp has passed according to the local clock.
  bool get isExpired {
    if (expiresAt == null) return false;
    return remainingDuration == Duration.zero;
  }

  /// Whether this code has the explicit no expiration policy.
  bool get neverExpires => expiresAt == null;
}

/// Roles assigned when a member joins through this code without approval.
///
/// An empty list means the code follows the approval flow. Role identifiers
/// are kept as typed record identifiers so the service can validate ownership
/// and assignability when the code is generated.
@freezed
abstract class JoinCodeAutoAccept with _$JoinCodeAutoAccept {
  const factory JoinCodeAutoAccept({@Default([]) List<skir.RecordId> roleIds}) =
      _JoinCodeAutoAccept;

  const JoinCodeAutoAccept._();

  /// Converts the protocol role policy into the panel model.
  factory JoinCodeAutoAccept.fromSkir(skir.JoinCode_AutoAccept request) =>
      JoinCodeAutoAccept(roleIds: request.roleIds.toList());

  /// Converts the selected role policy for a generation request.
  skir.JoinCode_AutoAccept toSkir() =>
      skir.JoinCode_AutoAccept(roleIds: roleIds);
}

/// The two expiration policies accepted by join code generation.
///
/// [never] creates a code without an expiry. [duration] is validated by the
/// service and by the duration input before the request is sent.
@freezed
sealed class JoinCodeExpiration with _$JoinCodeExpiration {
  const factory JoinCodeExpiration.never() = JoinCodeExpirationNever;
  const factory JoinCodeExpiration.duration(Duration duration) =
      JoinCodeExpirationDuration;
}

/// Panel intent used to generate an invitation code.
///
/// Defaults favor a one time code that expires after seven days and does not
/// auto accept members. The settings UI edits this value locally. It becomes
/// server state only when [OrganizationJoinCodes.generateCode] is called.
@freezed
abstract class JoinCodeOptions with _$JoinCodeOptions {
  const factory JoinCodeOptions({
    @Default(true) bool singleUse,
    @Default(JoinCodeExpiration.duration(Duration(days: 7)))
    JoinCodeExpiration expiration,
    @Default([]) List<skir.RecordId> autoAcceptRoleIds,
  }) = _JoinCodeOptions;
}

/// Owns the panel's live read model of invitation codes for the selected organization.
///
/// The provider waits for authentication and organization selection, then
/// watches the service for one snapshot followed by sequenced add and remove
/// changes. Duplicate changes are ignored. A sequence gap invalidates the
/// provider so the next subscription can recover from a fresh snapshot.
/// Mutations use this same owner to reconcile successful events and to roll
/// back an optimistic revoke when the request fails.
@riverpod
class OrganizationJoinCodes extends _$OrganizationJoinCodes {
  final _sequenceState = SequencedCollection<List<OrganizationJoinCode>>();

  @override
  Stream<List<OrganizationJoinCode>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (!ref.mounted) return;

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
    yield* ref.watchSequencedRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.watch",
      eventSubject:
          "cloud.from.organization.${organizationId.id}.join_codes.changed",
      requestBytes: skir.WatchOrganizationJoinCodesRequest.serializer.toBytes(
        request,
      ),
      responseSerializer: skir.WatchOrganizationJoinCodesResponse.serializer,
      eventSerializer: skir.OrganizationJoinCodesChanged.serializer,
      snapshot: (response) {
        return switch (response) {
          skir.WatchOrganizationJoinCodesResponse_unknown() =>
            throw ApiException.unknownResponseMessage(),
          skir.WatchOrganizationJoinCodesResponse_internalErrorWrapper() =>
            throw ApiException.internalServerError(),
          skir.WatchOrganizationJoinCodesResponse_snapshotWrapper(
            :final value,
          ) =>
            SequencedSnapshot(
              sequence: value.sequence,
              value: value.values.map(OrganizationJoinCode.fromSkir).toList(),
            ),
          skir.WatchOrganizationJoinCodesResponse_changedWrapper() =>
            throw StateError("Snapshot request returned a delta"),
        };
      },
      eventSequence: (event) => event.sequence,
      reduce: _reduceJoinCodes,
      sequenceState: _sequenceState,
    );
  }

  /// Requests a new invitation code using [options].
  ///
  /// The returned value is intended for immediate display in the secret field.
  /// The committed code also arrives through the organization change stream,
  /// which updates the provider projection. Authentication, organization
  /// context, invalid roles, invalid expiration, replay conflicts, and
  /// transport uncertainty are surfaced as [ApiException] values. A successful
  /// response is applied immediately so the caller does not wait for the event.
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
      operationId: uuid.v4(),
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

    final response = await ref.mutateSkir(
      "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.generate",
      skir.GenerateOrganizationJoinCodeRequest.serializer.toBytes(request),
      skir.GenerateOrganizationJoinCodeResponse.serializer,
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      label: "Generate join code",
      classify: (response) => switch (response) {
        skir.GenerateOrganizationJoinCodeResponse_successWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.GenerateOrganizationJoinCodeResponse_unknown() ||
        skir.GenerateOrganizationJoinCodeResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
    );

    switch (response) {
      case skir.GenerateOrganizationJoinCodeResponse_invalidOperationIdErrorWrapper():
        throw ApiException.badRequest("Operation identity is required");
      case skir.GenerateOrganizationJoinCodeResponse_operationIdentityReusedErrorWrapper():
        throw ApiException.conflict(
          "Operation identity was reused with different input",
        );
      case skir.GenerateOrganizationJoinCodeResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.GenerateOrganizationJoinCodeResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.GenerateOrganizationJoinCodeResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotFoundErrorWrapper():
        throw ApiException.notFound("Roles");
      case skir.GenerateOrganizationJoinCodeResponse_rolesNotAssignableErrorWrapper():
        throw ApiException.badRequest("One or more roles cannot be assigned");
      case skir.GenerateOrganizationJoinCodeResponse_invalidExpirationErrorWrapper():
        throw ApiException.badRequest("Expiration duration must be positive");
      case skir.GenerateOrganizationJoinCodeResponse_successWrapper(
        :final value,
      ):
        _applyEvent(value.event);
        return SecretFieldRevealed(
          value: value.code.code.id,
          expiresAt: value.code.expiresAt,
        );
    }
  }

  /// Removes codes expired according to the local clock from this projection.
  /// This is a display cleanup only. It does not revoke or alter service state.
  void cleanupExpiredCodes() {
    state.ensureReady();
    state = AsyncValue.data(
      state.requireValue.where((code) => !code.isExpired).toList(),
    );
  }

  /// Revokes [codeId] and removes it from the local projection immediately.
  ///
  /// The service owns the authoritative removal and emits the corresponding
  /// sequenced event after commit. Until the response is known, this method
  /// keeps the previous provider state for rollback. Any rejection or
  /// uncertain failure restores that state and invalidates the provider, so a
  /// later snapshot can reestablish the organization projection.
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

    // Hide the code while the service decides. Failure restores the snapshot
    // captured above, rather than leaving the UI to imply a committed revoke.
    state = AsyncValue.data(
      state.requireValue.where((c) => c.code != codeId).toList(),
    );

    try {
      final request = skir.RevokeOrganizationJoinCodeRequest(
        operationId: uuid.v4(),
        codeId: codeId,
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.join_codes.revoke",
        skir.RevokeOrganizationJoinCodeRequest.serializer.toBytes(request),
        skir.RevokeOrganizationJoinCodeResponse.serializer,
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Revoke join code",
        resources: {(organizationId, codeId)},
        classify: (response) => switch (response) {
          skir.RevokeOrganizationJoinCodeResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.RevokeOrganizationJoinCodeResponse_unknown() ||
          skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.RevokeOrganizationJoinCodeResponse_invalidOperationIdErrorWrapper():
          throw ApiException.badRequest("Operation identity is required");
        case skir.RevokeOrganizationJoinCodeResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.RevokeOrganizationJoinCodeResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.RevokeOrganizationJoinCodeResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.RevokeOrganizationJoinCodeResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.RevokeOrganizationJoinCodeResponse_codeNotFoundErrorWrapper():
          throw ApiException.notFound("Join Code");
        case skir.RevokeOrganizationJoinCodeResponse_successWrapper(
          :final value,
        ):
          _applyEvent(value.event);
          debugPrint("Join code $codeId revoked successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  // Applies a committed service event only when its sequence can extend the
  // current projection. A gap requires a new snapshot instead of guessing the
  // missing changes.
  void _applyEvent(skir.OrganizationJoinCodesChanged event) {
    switch (_sequenceState.apply(
      sequence: event.sequence,
      reduce: (codes) => _reduceJoinCodes(codes, event),
    )) {
      case SequencedEventResult.duplicate:
        return;
      case SequencedEventResult.applied:
        state = AsyncData(_sequenceState.value);
      case SequencedEventResult.gap:
        ref.invalidateSelf();
    }
  }
}

// The reducer is shared by initial event delivery and mutation responses so
// both paths apply add and remove changes with the same ordering and identity
// rules.
List<OrganizationJoinCode> _reduceJoinCodes(
  List<OrganizationJoinCode> codes,
  skir.OrganizationJoinCodesChanged event,
) {
  return event.changes.fold(codes, (current, change) {
    return switch (change) {
      skir.OrganizationJoinCodesChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationJoinCodesChange_addWrapper(:final value) =>
        current.upsertByKey(
          (code) => code.code,
          OrganizationJoinCode.fromSkir(value),
        ),
      skir.OrganizationJoinCodesChange_removeWrapper(:final value) =>
        current.where((code) => code.code != value).toList(),
    };
  });
}

/// Derives the number of currently usable codes from the live projection.
///
/// Loading and error states intentionally report zero because this value is a
/// navigation badge, not an authority for whether generation or revocation is
/// allowed. Expired codes remain in the projection until the visible countdown
/// removes them locally or a service change replaces the snapshot.
@riverpod
int joinCodeCount(Ref ref) {
  final codes = ref.watch(organizationJoinCodesProvider);
  return codes.maybeWhen(
    data: (data) => data.where((code) => !code.isExpired).length,
    orElse: () => 0,
  );
}
