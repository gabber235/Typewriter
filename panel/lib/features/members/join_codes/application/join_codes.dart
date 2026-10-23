import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "join_codes.freezed.dart";
part "join_codes.g.dart";

/// Local expiry of an organization owned invitation code.
///
/// The service owns creation, expiration, consumption, and revocation. A null
/// [skir.JoinCode.expiresAt] is the explicit never expires state, not an
/// unknown timestamp. An empty auto accept role list means the code follows
/// the approval flow.
extension JoinCodeExpiry on skir.JoinCode {
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
/// server state only when a membership command is executed.
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
/// [MembershipResourceRepository] owns commands and supplies confirmed facts.
/// Derived visibility hides expired and pending rows without changing this
/// authoritative snapshot.
@riverpod
class OrganizationJoinCodes extends _$OrganizationJoinCodes {
  final _sequenceState = SequencedCollection<List<skir.JoinCode>>();

  @override
  Stream<List<skir.JoinCode>> build() async* {
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
    final request = skir.WatchOrganizationJoinCodesRequest();
    yield* request.watch<List<skir.JoinCode>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) => _joinCodeSnapshot(response).values.toList(),
      reduce: _reduceJoinCodes,
      confirmedEvents: repository.codes,
      reconciliation: ProjectionReconciliation.sequenced(
        snapshotSequence: (response) => _joinCodeSnapshot(response).sequence,
        eventSequence: (event) => event.sequence,
        sequenceState: _sequenceState,
      ),
    );
  }
}

skir.OrganizationJoinCodesSnapshot _joinCodeSnapshot(
  skir.WatchOrganizationJoinCodesResponse response,
) => switch (response) {
  skir.WatchOrganizationJoinCodesResponse_snapshotWrapper(:final value) =>
    value,
  skir.WatchOrganizationJoinCodesResponse_unknown() =>
    throw ApiException.unknownResponseMessage(),
  skir.WatchOrganizationJoinCodesResponse_internalErrorWrapper() =>
    throw ApiException.internalServerError(),
  skir.WatchOrganizationJoinCodesResponse_changedWrapper() => throw StateError(
    "Snapshot request returned a delta",
  ),
};

// The reducer is shared by initial event delivery and mutation responses so
// both paths apply add and remove changes with the same ordering and identity
// rules.
List<skir.JoinCode> _reduceJoinCodes(
  List<skir.JoinCode> codes,
  skir.OrganizationJoinCodesChanged event,
) {
  return event.changes.fold(codes, (current, change) {
    return switch (change) {
      skir.OrganizationJoinCodesChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationJoinCodesChange_addWrapper(:final value) =>
        current.upsertByKey((code) => code.code, value),
      skir.OrganizationJoinCodesChange_removeWrapper(:final value) =>
        current.where((code) => code.code != value).toList(),
    };
  });
}

/// Derives the number of currently usable codes from the live projection.
///
/// Loading and error states intentionally report zero because this value is a
/// navigation badge, not an authority for whether generation or revocation is
/// allowed. Display time filters the authoritative projection without writing
/// to its sequence state.
@riverpod
int joinCodeCount(Ref ref) {
  final codes = ref.watch(visibleOrganizationJoinCodesProvider);
  return codes.maybeWhen(data: (data) => data.length, orElse: () => 0);
}
