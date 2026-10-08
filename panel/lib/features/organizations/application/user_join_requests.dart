import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "user_join_requests.freezed.dart";
part "user_join_requests.g.dart";

/// The requesting user's read model for one pending organization invitation.
///
/// This projection carries organization display data because it is not scoped to
/// one organization. Expiry is server supplied; local expiry only removes stale
/// UI rows and does not cancel the server request.
@freezed
abstract class UserJoinRequest with _$UserJoinRequest {
  const factory UserJoinRequest({
    required skir.RecordId requestId,
    required skir.RecordId organizationId,
    required String organizationName,
    required String organizationLogoUrl,
    required DateTime requestedAt,
    required DateTime expiresAt,
  }) = _UserJoinRequest;

  const UserJoinRequest._();

  /// Converts the user scoped wire projection into a panel read model.
  factory UserJoinRequest.fromSkir(skir.UserJoinRequest request) {
    return UserJoinRequest(
      requestId: request.requestId,
      organizationId: request.organizationId,
      organizationName: request.organizationName,
      organizationLogoUrl: request.organizationLogoUrl,
      requestedAt: request.requestedAt,
      expiresAt: request.expiresAt,
    );
  }

  /// Converts this read model back to the shared wire shape.
  skir.UserJoinRequest toSkir() {
    return skir.UserJoinRequest(
      requestId: requestId,
      organizationId: this.organizationId,
      organizationName: organizationName,
      organizationLogoUrl: organizationLogoUrl,
      requestedAt: requestedAt,
      expiresAt: expiresAt,
    );
  }

  /// Time remaining according to the local clock, clamped at zero.
  Duration get remainingDuration {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether this request should be hidden from active pending UI.
  bool get isExpired => remainingDuration == Duration.zero;
}

/// Owns the authenticated user's pending join request projection.
///
/// Snapshot and change events are reconciled by the user scoped sequence. A gap
/// invalidates the provider for a fresh snapshot. Mutations use operation
/// identities and classify uncertain responses through the shared mutation layer.
/// Cancellation is optimistic, but any failure restores the previous list and
/// invalidates the stream so recovery uses server state.
@riverpod
class UserJoinRequests extends _$UserJoinRequests {
  final _sequenceState = SequencedCollection<List<UserJoinRequest>>();

  @override
  Stream<List<UserJoinRequest>> build() async* {
    final userId = await ref.watch(userIdProvider.future);
    if (userId == null) {
      yield [];
      return;
    }

    final request = skir.WatchUserJoinRequestsRequest();
    yield* ref.watchSequencedRequest(
      subject: "cloud.to.user.$userId.organization.join_requests.watch",
      eventSubject: "cloud.from.user.$userId.join_requests.changed",
      requestBytes: skir.WatchUserJoinRequestsRequest.serializer.toBytes(
        request,
      ),
      responseSerializer: skir.WatchUserJoinRequestsResponse.serializer,
      eventSerializer: skir.UserJoinRequestsChanged.serializer,
      snapshot: (response) {
        return switch (response) {
          skir.WatchUserJoinRequestsResponse_unknown() =>
            throw ApiException.unknownResponseMessage(),
          skir.WatchUserJoinRequestsResponse_internalErrorWrapper() =>
            throw ApiException.internalServerError(),
          skir.WatchUserJoinRequestsResponse_snapshotWrapper(:final value) =>
            SequencedSnapshot(
              sequence: value.sequence,
              value: value.values.map(UserJoinRequest.fromSkir).toList(),
            ),
          skir.WatchUserJoinRequestsResponse_changedWrapper() =>
            throw StateError("Snapshot request returned a delta"),
        };
      },
      eventSequence: (event) => event.sequence,
      reduce: _reduceUserJoinRequests,
      sequenceState: _sequenceState,
    );
  }

  /// Submits a request using either an invite code or an invite URL.
  ///
  /// The caller supplies user input, while this owner extracts the code, creates
  /// the operation identity, submits the mutation, and applies the success event.
  /// Server rejection remains an [ApiException], including already joined,
  /// duplicate pending, expired code, and pending limit outcomes.
  Future<void> requestToJoin(String urlOrCode) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    state.ensureReady();
    final code = _extractCode(urlOrCode);
    final codeId = skir.recordId("organization_join_code:$code");

    final request = skir.SubmitUserJoinRequestRequest(
      operationId: uuid.v4(),
      code: codeId,
    );

    final response = await ref.mutateSkir(
      "cloud.to.user.$userId.organization.join_requests.request",
      skir.SubmitUserJoinRequestRequest.serializer.toBytes(request),
      skir.SubmitUserJoinRequestResponse.serializer,
      submissionId: request.operationId,
      replay: SubmissionReplay.identicalRequest,
      label: "Request membership",
      classify: (response) => switch (response) {
        skir.SubmitUserJoinRequestResponse_requestMadeWrapper() ||
        skir.SubmitUserJoinRequestResponse_autoAcceptedWrapper() =>
          MutationResponseDisposition.confirmed,
        skir.SubmitUserJoinRequestResponse_unknown() ||
        skir.SubmitUserJoinRequestResponse_internalErrorWrapper() =>
          MutationResponseDisposition.uncertain,
        _ => MutationResponseDisposition.rejected,
      },
    );

    switch (response) {
      case skir.SubmitUserJoinRequestResponse_invalidOperationIdErrorWrapper():
        throw ApiException.badRequest("Operation identity is required");
      case skir.SubmitUserJoinRequestResponse_operationIdentityReusedErrorWrapper():
        throw ApiException.conflict(
          "Operation identity was reused with different input",
        );
      case skir.SubmitUserJoinRequestResponse_unknown():
        throw ApiException.unknownResponseMessage();
      case skir.SubmitUserJoinRequestResponse_codeNotFoundErrorWrapper():
        throw ApiException.notFound("Join code not found or expired");
      case skir.SubmitUserJoinRequestResponse_internalErrorWrapper():
        throw ApiException.internalServerError();
      case skir.SubmitUserJoinRequestResponse_invalidRecordIdErrorWrapper(
        :final value,
      ):
        throw ApiException.invalidRecordId(value);
      case skir.SubmitUserJoinRequestResponse_alreadyMemberErrorWrapper():
        throw ApiException.conflict(
          "You are already a member of this organization",
        );
      case skir.SubmitUserJoinRequestResponse_noAssignableRolesErrorWrapper():
        throw ApiException.badRequest(
          "No assignable roles available for this organization",
        );
      case skir.SubmitUserJoinRequestResponse_maxPendingRequestsErrorWrapper():
        throw ApiException.badRequest("Maximum pending join requests reached");
      case skir.SubmitUserJoinRequestResponse_pendingRequestExistsErrorWrapper():
        throw ApiException.conflict(
          "You already have a pending join request for this organization",
        );
      case skir.SubmitUserJoinRequestResponse_requestMadeWrapper(:final value):
        _applyEvent(value.event);
      case skir.SubmitUserJoinRequestResponse_autoAcceptedWrapper():
        debugPrint("User was auto-accepted as a member");
    }
  }

  /// Cancels one pending request with an optimistic local removal.
  ///
  /// The prior projection is restored when the mutation fails, then the stream is
  /// invalidated to reconcile any concurrent server decision.
  Future<void> cancelRequest(skir.RecordId requestId) async {
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      throw ApiException.notAuthenticated();
    }

    state.ensureReady();
    final previousState = state;

    state = AsyncValue.data(
      state.requireValue.where((r) => r.requestId != requestId).toList(),
    );

    try {
      final request = skir.CancelUserJoinRequestRequest(
        operationId: uuid.v4(),
        requestId: requestId,
      );

      final response = await ref.mutateSkir(
        "cloud.to.user.$userId.organization.join_requests.cancel",
        skir.CancelUserJoinRequestRequest.serializer.toBytes(request),
        skir.CancelUserJoinRequestResponse.serializer,
        submissionId: request.operationId,
        replay: SubmissionReplay.identicalRequest,
        label: "Cancel membership request",
        classify: (response) => switch (response) {
          skir.CancelUserJoinRequestResponse_successWrapper() =>
            MutationResponseDisposition.confirmed,
          skir.CancelUserJoinRequestResponse_unknown() ||
          skir.CancelUserJoinRequestResponse_internalErrorWrapper() =>
            MutationResponseDisposition.uncertain,
          _ => MutationResponseDisposition.rejected,
        },
      );

      switch (response) {
        case skir.CancelUserJoinRequestResponse_invalidOperationIdErrorWrapper():
          throw ApiException.badRequest("Operation identity is required");
        case skir.CancelUserJoinRequestResponse_operationIdentityReusedErrorWrapper():
          throw ApiException.conflict(
            "Operation identity was reused with different input",
          );
        case skir.CancelUserJoinRequestResponse_unknown():
          throw ApiException.unknownResponseMessage();
        case skir.CancelUserJoinRequestResponse_internalErrorWrapper():
          throw ApiException.internalServerError();
        case skir.CancelUserJoinRequestResponse_invalidRecordIdErrorWrapper(
          :final value,
        ):
          throw ApiException.invalidRecordId(value);
        case skir.CancelUserJoinRequestResponse_requestNotFoundErrorWrapper():
          throw ApiException.notFound("Join request not found");
        case skir.CancelUserJoinRequestResponse_successWrapper(:final value):
          _applyEvent(value.event);
          debugPrint("Join request $requestId cancelled successfully");
      }
    } catch (e) {
      state = previousState;
      ref.invalidateSelf();
      rethrow;
    }
  }

  void _applyEvent(skir.UserJoinRequestsChanged event) {
    switch (_sequenceState.apply(
      sequence: event.sequence,
      reduce: (requests) => _reduceUserJoinRequests(requests, event),
    )) {
      case SequencedEventResult.duplicate:
        return;
      case SequencedEventResult.applied:
        state = AsyncData(_sequenceState.value);
      case SequencedEventResult.gap:
        ref.invalidateSelf();
    }
  }

  /// Extracts the final path segment from a URL, or preserves a raw code.
  String _extractCode(String urlOrCode) {
    final uri = Uri.tryParse(urlOrCode);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return urlOrCode;
  }

  /// Removes expired rows from the local projection without contacting the server.
  ///
  /// The next snapshot or change event remains authoritative if the server still
  /// reports a request.
  void cleanupExpiredRequests() {
    state = AsyncData(
      state.requireValue.where((request) => !request.isExpired).toList(),
    );
  }
}

List<UserJoinRequest> _reduceUserJoinRequests(
  List<UserJoinRequest> requests,
  skir.UserJoinRequestsChanged event,
) {
  return event.changes.fold(requests, (current, change) {
    return switch (change) {
      skir.UserJoinRequestsChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.UserJoinRequestsChange_addWrapper(:final value) =>
        current.upsertByKey(
          (request) => request.requestId,
          UserJoinRequest.fromSkir(value),
        ),
      skir.UserJoinRequestsChange_removeWrapper(:final value) =>
        current.where((request) => request.requestId != value).toList(),
    };
  });
}
