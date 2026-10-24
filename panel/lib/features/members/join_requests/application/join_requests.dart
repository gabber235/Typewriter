import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "join_requests.g.dart";

/// Local expiry of an organization scoped pending membership request.
///
/// The provider below owns the live projection. Visibility derives expiry and
/// pending removals without mutating that authoritative projection.
extension OrganizationJoinRequestExpiry on skir.OrganizationJoinRequest {
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
  final _sequenceState =
      SequencedCollection<List<skir.OrganizationJoinRequest>>();

  @override
  Stream<List<skir.OrganizationJoinRequest>> build() async* {
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

    final repository = ref.watch(
      membershipResourceRepositoryProvider(organizationId),
    );
    final request = skir.WatchOrganizationJoinRequestsRequest();
    yield* request.watch<List<skir.OrganizationJoinRequest>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) => _joinRequestSnapshot(response).values.toList(),
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
List<skir.OrganizationJoinRequest> _reduceOrganizationJoinRequests(
  List<skir.OrganizationJoinRequest> requests,
  skir.OrganizationJoinRequestsChanged event,
) {
  return event.changes.fold(requests, (current, change) {
    return switch (change) {
      skir.OrganizationJoinRequestsChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationJoinRequestsChange_addWrapper(:final value) =>
        current.upsertByKey((request) => request.requestId, value),
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
