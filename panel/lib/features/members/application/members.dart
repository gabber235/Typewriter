import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "members.g.dart";
part "membership_outcomes.dart";
part "membership_resource_repository.dart";

/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.
@riverpod
class OrganizationMembers extends _$OrganizationMembers {
  @protected
  final sequencedCollection =
      SequencedCollection<List<skir.OrganizationMember>>();

  @override
  Stream<List<skir.OrganizationMember>> build() async* {
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
    final request = skir.WatchOrganizationMembersRequest();
    yield* request.watch<List<skir.OrganizationMember>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) => switch (response) {
        skir.WatchOrganizationMembersResponse_unknown() =>
          throw ApiException.unknownResponseMessage(),
        skir.WatchOrganizationMembersResponse_internalErrorWrapper() =>
          throw ApiException.internalServerError(),
        skir.WatchOrganizationMembersResponse_snapshotWrapper(:final value) =>
          value.values.toList(),
      },
      reduce: _reduceMembers,
      confirmedEvents: repository.members,
      reconciliation: ProjectionReconciliation.sequenced(
        snapshotSequence: (response) => response.readSnapshot().sequence,
        eventSequence: (event) => event.sequence,
        sequenceState: sequencedCollection,
      ),
    );
  }

  /// Preserves protected roles while normalizing an editor's assignable role
  /// choice. If the choice would leave a member without roles, returns the
  /// organization's default role instead of emitting an invalid request.
  Future<List<skir.OrganizationRole>> ensureCorrectRoles(
    skir.RecordId memberId,
    List<skir.OrganizationRole> newRoles,
  ) async {
    final oldRoles =
        state.requireValue
            .firstWhereOrNull((m) => m.userId == memberId)
            ?.roles ??
        [];

    final roles = {
      ...oldRoles.where((r) => !r.assignable),
      ...newRoles.where((r) => r.assignable),
    };

    if (roles.isEmpty) {
      final availableRoles = await ref.read(organizationRolesProvider.future);
      final defaultRoles = availableRoles
          .where((role) => role.defaultRole)
          .toList();
      assert(defaultRoles.isNotEmpty, "No default roles available.");
      return defaultRoles;
    }

    return roles.toList();
  }

  @override
  bool updateShouldNotify(
    AsyncValue<List<skir.OrganizationMember>> previous,
    AsyncValue<List<skir.OrganizationMember>> next,
  ) => true;
}

extension MemberSnapshotReply on skir.WatchOrganizationMembersResponse {
  skir.OrganizationMembersSnapshot readSnapshot() => switch (this) {
    skir.WatchOrganizationMembersResponse_snapshotWrapper(:final value) =>
      value,
    skir.WatchOrganizationMembersResponse_internalErrorWrapper() =>
      throw ApiException.internalServerError(),
    skir.WatchOrganizationMembersResponse_unknown() =>
      throw ApiException.unknownResponseMessage(),
  };
}

/// Reduces complete add and update values, plus identity only removals, into
/// the immutable member list used by the provider state.
List<skir.OrganizationMember> _reduceMembers(
  List<skir.OrganizationMember> members,
  skir.OrganizationMembersChanged event,
) {
  return event.changes.fold(members, (current, change) {
    return switch (change) {
      skir.OrganizationMembersChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationMembersChange_addWrapper(:final value) ||
      skir.OrganizationMembersChange_updateWrapper(
        :final value,
      ) => current.upsertByKey((member) => member.userId, value),
      skir.OrganizationMembersChange_removeWrapper(:final value) =>
        current.where((member) => member.userId != value).toList(),
    };
  });
}
