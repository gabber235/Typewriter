import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "join_requests.freezed.dart";
part "join_requests.g.dart";

/// Organization scoped moderation data for pending membership requests.
///
/// The provider below owns the live projection and the approve and decline
/// mutations. The projection starts from a sequenced server snapshot, applies
/// later organization events in order, and invalidates itself on a sequence
/// gap. The UI may remove expired rows locally, but the server remains
/// authoritative for membership decisions and later reconciliation.
@freezed
abstract class OrganizationJoinRequest with _$OrganizationJoinRequest {
  /// The organization scoped read model shown to membership moderators.
  const factory OrganizationJoinRequest({
    required skir.RecordId requestId,
    required skir.RecordId userId,
    required DateTime requestedAt,
    required DateTime expiresAt,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
  }) = _OrganizationJoinRequest;

  const OrganizationJoinRequest._();

  /// Converts the moderation projection from the shared wire contract.
  factory OrganizationJoinRequest.fromSkir(
    skir.OrganizationJoinRequest request,
  ) => OrganizationJoinRequest(
    requestId: request.requestId,
    userId: request.userId,
    requestedAt: request.requestedAt,
    expiresAt: request.expiresAt,
    userName: request.userName,
    userEmail: request.userEmail,
    userAvatarUrl: request.userAvatarUrl,
  );

  /// Converts this panel read model back to the shared wire shape.
  skir.OrganizationJoinRequest toSkir() => skir.OrganizationJoinRequest(
    requestId: requestId,
    userId: this.userId,
    requestedAt: requestedAt,
    expiresAt: expiresAt,
    userName: userName,
    userEmail: userEmail,
    userAvatarUrl: userAvatarUrl,
  );

  /// Returns locally calculated time remaining, clamped at zero.
  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether this row should be hidden from active pending request UI.
  bool get isExpired => remainingDuration == Duration.zero;
}

/// Owns the current organization moderation projection and its mutations.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Approval is one server transaction for all selected requests and
/// roles, while decline removes one request optimistically. Both mutations use
/// operation identities and classify uncertain delivery through the shared
/// mutation layer. Failed mutations invalidate the provider so the next
/// snapshot resolves concurrent server decisions; decline also restores its
/// prior local projection before that refresh.
@riverpod
class OrganizationJoinRequests extends _$OrganizationJoinRequests {
  final _sequenceState = SequencedCollection<List<OrganizationJoinRequest>>();

  @override
  Stream<List<OrganizationJoinRequest>> build() async* {
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

    final request = skir.WatchOrganizationJoinRequestsRequest();
    yield* ref.watchSequencedRequest(
      subject:
          "cloud.to.user.$userId.organization.${organizationId.id}.members.join_requests.watch",
      eventSubject:
          "cloud.from.organization.${organizationId.id}.join_requests.changed",
      requestBytes: skir.WatchOrganizationJoinRequestsRequest.serializer
          .toBytes(request),
      responseSerializer: skir.WatchOrganizationJoinRequestsResponse.serializer,
      eventSerializer: skir.OrganizationJoinRequestsChanged.serializer,
      snapshot: (response) {
        return switch (response) {
          skir.WatchOrganizationJoinRequestsResponse_unknown() =>
            throw ApiException.unknownResponseMessage(),
          skir.WatchOrganizationJoinRequestsResponse_internalErrorWrapper() =>
            throw ApiException.internalServerError(),
          skir.WatchOrganizationJoinRequestsResponse_snapshotWrapper(
            :final value,
          ) =>
            SequencedSnapshot(
              sequence: value.sequence,
              value: value.values
                  .map(OrganizationJoinRequest.fromSkir)
                  .toList(),
            ),
          skir.WatchOrganizationJoinRequestsResponse_changedWrapper() =>
            throw StateError("Snapshot request returned a delta"),
        };
      },
      eventSequence: (event) => event.sequence,
      reduce: _reduceOrganizationJoinRequests,
      sequenceState: _sequenceState,
    );
  }

  /// Approves the selected pending requests and assigns one role set to each.
  ///
  /// The server validates the complete selection atomically. A rejection leaves
  /// every request pending. A confirmed response includes the organization
  /// change event, which is applied immediately when this provider still owns
  /// the same organization; the stream remains the recovery path for events
  /// received later or after a provider restart.
  Future<void> approveRequests(
    Iterable<skir.RecordId> requestIds,
    List<OrganizationRole> roles,
  ) async {
    final ids = List<skir.RecordId>.unmodifiable(requestIds);
    final selectedRoles = List<OrganizationRole>.unmodifiable(roles);
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    try {
      final request = skir.ApproveOrganizationJoinRequestsRequest(
        operationId: uuid.v4(),
        requestIds: ids,
        roleIds: selectedRoles.map((r) => r.roleId),
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.join_requests.approve",
        skir.ApproveOrganizationJoinRequestsRequest.serializer.toBytes(request),
        skir.ApproveOrganizationJoinRequestsResponse.serializer,
        onResponse: (response) async {
          if (!ref.mounted ||
              ref.read(organizationIdProvider) != organizationId) {
            return;
          }
          if (response
              case skir.ApproveOrganizationJoinRequestsResponse_successWrapper(
                :final value,
              )) {
            _applyEvent(value.joinRequestsEvent);
          }
        },
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Approve membership",
        resources: {for (final id in ids) (organizationId, id)},
        classify: (response) => switch (response) {
          skir.ApproveOrganizationJoinRequestsResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.ApproveOrganizationJoinRequestsResponse_unknown() ||
          skir.ApproveOrganizationJoinRequestsResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.ApproveOrganizationJoinRequestsResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.ApproveOrganizationJoinRequestsResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.ApproveOrganizationJoinRequestsResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.ApproveOrganizationJoinRequestsResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Request");
        case skir.ApproveOrganizationJoinRequestsResponse_rolesNotFoundErrorWrapper():
          throw ApiException.notFound("Roles");
        case skir.ApproveOrganizationJoinRequestsResponse_rolesNotAssignableErrorWrapper():
          throw ApiException.badRequest("One or more roles cannot be assigned");
        case skir.ApproveOrganizationJoinRequestsResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.ApproveOrganizationJoinRequestsResponse_invalidSelectionErrorWrapper():
          throw ApiException.badRequest("Select distinct pending requests");
        case skir.ApproveOrganizationJoinRequestsResponse_rolesRequiredErrorWrapper():
          throw ApiException.badRequest("At least one role is required");
        case skir.ApproveOrganizationJoinRequestsResponse_userAlreadyMemberErrorWrapper():
          throw ApiException.conflict("User is already an organization member");
        case skir.ApproveOrganizationJoinRequestsResponse_successWrapper():
          break;
      }
    } catch (e) {
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Applies an event only when it continues the owned sequence.
  ///
  /// Duplicates are harmless. A gap discards the local assumption and asks the
  /// provider for a fresh snapshot instead of inventing missing changes.
  void _applyEvent(skir.OrganizationJoinRequestsChanged event) {
    switch (_sequenceState.apply(
      sequence: event.sequence,
      reduce: (requests) => _reduceOrganizationJoinRequests(requests, event),
    )) {
      case SequencedEventResult.duplicate:
        return;
      case SequencedEventResult.applied:
        state = AsyncData(_sequenceState.value);
      case SequencedEventResult.gap:
        ref.invalidateSelf();
    }
  }

  /// Declines one pending request with an optimistic local removal.
  ///
  /// The server removes the request from both organization and user views. If
  /// delivery or validation fails, the previous projection is restored and the
  /// provider is invalidated so recovery uses authoritative server state.
  Future<void> declineRequest(skir.RecordId requestId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }
    final organizationId = ref.read(organizationIdProvider);
    if (organizationId == null) {
      throw ApiException.noOrganization();
    }

    final previousState = state;

    state = AsyncValue.data(
      state.value!.where((r) => r.requestId != requestId).toList(),
    );

    try {
      final request = skir.DeclineOrganizationJoinRequestRequest(
        operationId: uuid.v4(),
        requestId: requestId,
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.${organizationId.id}.members.join_requests.decline",
        skir.DeclineOrganizationJoinRequestRequest.serializer.toBytes(request),
        skir.DeclineOrganizationJoinRequestResponse.serializer,
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Decline membership",
        resources: {(organizationId, requestId)},
        classify: (response) => switch (response) {
          skir.DeclineOrganizationJoinRequestResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.DeclineOrganizationJoinRequestResponse_unknown() ||
          skir.DeclineOrganizationJoinRequestResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.DeclineOrganizationJoinRequestResponse_invalidOperationIdErrorWrapper():
          throw ApiException.badRequest("Operation identity is required");
        case skir.DeclineOrganizationJoinRequestResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.DeclineOrganizationJoinRequestResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.DeclineOrganizationJoinRequestResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.DeclineOrganizationJoinRequestResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.DeclineOrganizationJoinRequestResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Request");
        case skir.DeclineOrganizationJoinRequestResponse_successWrapper():
          debugPrint("Request $requestId declined successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Removes expired rows from the local projection without contacting the
  /// server. A later snapshot or change event can restore a row if the server
  /// still reports it.
  void cleanupExpiredRequests() {
    state = AsyncData(
      state.requireValue.where((request) => !request.isExpired).toList(),
    );
  }
}

/// Folds one ordered organization event into the moderation projection.
List<OrganizationJoinRequest> _reduceOrganizationJoinRequests(
  List<OrganizationJoinRequest> requests,
  skir.OrganizationJoinRequestsChanged event,
) {
  return event.changes.fold(requests, (current, change) {
    return switch (change) {
      skir.OrganizationJoinRequestsChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationJoinRequestsChange_addWrapper(:final value) =>
        current.upsertByKey(
          (request) => request.requestId,
          OrganizationJoinRequest.fromSkir(value),
        ),
      skir.OrganizationJoinRequestsChange_removeWrapper(:final value) =>
        current.where((request) => request.requestId != value).toList(),
    };
  });
}

/// Counts unexpired requests in the current moderation projection.
///
/// Loading and error states report zero because the sidebar badge cannot claim
/// a pending count until the projection is available.
@riverpod
int joinRequestCount(Ref ref) {
  final requests = ref.watch(organizationJoinRequestsProvider);
  return requests.maybeWhen(
    data: (data) => data.where((request) => !request.isExpired).length,
    orElse: () => 0,
  );
}
