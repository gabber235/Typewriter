import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "join_requests.freezed.dart";
part "join_requests.g.dart";

/// Organization scoped moderation data for pending membership requests.
///
/// The provider below owns the live projection. The projection starts from a
/// sequenced server snapshot and applies later organization events in order.
/// [MembershipResourceRepository] owns moderation commands and supplies their
/// confirmed facts. Visibility derives expiry and pending removals without
/// mutating this authoritative projection.
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

/// Owns the current organization moderation projection.
///
/// The authenticated user and selected organization determine the stream
/// subjects. Sequenced broker events and confirmed command facts share one
/// admission path. Expired and pending rows are filtered by the derived
/// visibility providers while this owner retains the complete server snapshot.
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

    final repository = ref
        .watch(resourceRepositoriesProvider)
        .membership(organizationId);
    final request = skir.WatchOrganizationJoinRequestsRequest();
    yield* request.watch<List<OrganizationJoinRequest>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) =>
          _joinRequestSnapshot(response).values
              .map(OrganizationJoinRequest.fromSkir)
              .toList(),
      reduce: _reduceOrganizationJoinRequests,
      confirmedEvents: repository.requests,
      reconciliation: ProjectionReconciliation.sequenced(
        snapshotSequence: (response) => _joinRequestSnapshot(response).sequence,
        eventSequence: (event) => event.sequence,
        sequenceState: _sequenceState,
      ),
    );
  }
}

skir.OrganizationJoinRequestsSnapshot _joinRequestSnapshot(
  skir.WatchOrganizationJoinRequestsResponse response,
) => switch (response) {
  skir.WatchOrganizationJoinRequestsResponse_snapshotWrapper(:final value) =>
    value,
  skir.WatchOrganizationJoinRequestsResponse_unknown() =>
    throw ApiException.unknownResponseMessage(),
  skir.WatchOrganizationJoinRequestsResponse_internalErrorWrapper() =>
    throw ApiException.internalServerError(),
  skir.WatchOrganizationJoinRequestsResponse_changedWrapper() =>
    throw StateError("Snapshot request returned a delta"),
};

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
  final requests = ref.watch(visibleOrganizationJoinRequestsProvider);
  return requests.maybeWhen(
    data: (data) => data.where((request) => !request.isExpired).length,
    orElse: () => 0,
  );
}
