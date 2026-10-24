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

    final repository = ref
        .watch(resourceRepositoriesProvider)
        .membership(organizationId);
    final request = skir.WatchOrganizationJoinCodesRequest();
    yield* request.watch<List<OrganizationJoinCode>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) =>
          _joinCodeSnapshot(response).values
              .map(OrganizationJoinCode.fromSkir)
              .toList(),
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
/// allowed. Display time filters the authoritative projection without writing
/// to its sequence state.
@riverpod
int joinCodeCount(Ref ref) {
  final codes = ref.watch(visibleOrganizationJoinCodesProvider);
  return codes.maybeWhen(data: (data) => data.length, orElse: () => 0);
}
