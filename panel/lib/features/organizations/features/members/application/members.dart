import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "members.freezed.dart";
part "members.g.dart";
part "membership_outcomes.dart";
part "membership_resource_repository.dart";

/// Client model for one organization member.
///
/// The server projection is authoritative. The nullable profile fields are
/// observations supplied by the identity system, while [roles] and [joinedAt]
/// describe the membership projection. Conversion methods keep the UI model
/// separate from generated protocol values.
@freezed
abstract class OrganizationMember with _$OrganizationMember {
  const factory OrganizationMember({
    required skir.RecordId userId,
    required List<OrganizationRole> roles,
    required DateTime joinedAt,
    String? name,
    String? email,
    String? avatarUrl,
  }) = _OrganizationMember;

  const OrganizationMember._();

  factory OrganizationMember.fromSkir(skir.OrganizationMember member) =>
      OrganizationMember(
        userId: member.userId,
        name: member.name,
        email: member.email,
        avatarUrl: member.avatarUrl,
        roles: member.roles.map(OrganizationRole.fromSkir).toList(),
        joinedAt: member.joinedAt,
      );

  skir.OrganizationMember toSkir() => skir.OrganizationMember(
    userId: this.userId,
    name: name,
    email: email,
    avatarUrl: avatarUrl,
    roles: roles.map((r) => r.toSkir()),
    joinedAt: joinedAt,
  );
}

/// Owns the current organization's member projection.
///
/// The provider starts with a snapshot, applies later sequenced changes, and
/// invalidates itself when a sequence gap makes the local projection unsafe to
/// trust. [MembershipResourceRepository] owns commands and feeds confirmed
/// events through the same ordered projection path as broker events.
@riverpod
class OrganizationMembers extends _$OrganizationMembers {
  @protected
  final sequencedCollection = SequencedCollection<List<OrganizationMember>>();

  @override
  Stream<List<OrganizationMember>> build() async* {
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
    yield* request.watch<List<OrganizationMember>>(
      ref,
      userId: userId,
      organizationId: organizationId,
      snapshot: (response) => switch (response) {
        skir.WatchOrganizationMembersResponse_unknown() =>
          throw ApiException.unknownResponseMessage(),
        skir.WatchOrganizationMembersResponse_internalErrorWrapper() =>
          throw ApiException.internalServerError(),
        skir.WatchOrganizationMembersResponse_snapshotWrapper(:final value) =>
          value.values.map(OrganizationMember.fromSkir).toList(),
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
  Future<List<OrganizationRole>> ensureCorrectRoles(
    skir.RecordId memberId,
    List<OrganizationRole> newRoles,
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
    AsyncValue<List<OrganizationMember>> previous,
    AsyncValue<List<OrganizationMember>> next,
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
List<OrganizationMember> _reduceMembers(
  List<OrganizationMember> members,
  skir.OrganizationMembersChanged event,
) {
  return event.changes.fold(members, (current, change) {
    return switch (change) {
      skir.OrganizationMembersChange_unknown() =>
        throw ApiException.unknownResponseMessage(),
      skir.OrganizationMembersChange_addWrapper(:final value) ||
      skir.OrganizationMembersChange_updateWrapper(
        :final value,
      ) => current.upsertByKey(
        (member) => member.userId,
        OrganizationMember.fromSkir(value),
      ),
      skir.OrganizationMembersChange_removeWrapper(:final value) =>
        current.where((member) => member.userId != value).toList(),
    };
  });
}
