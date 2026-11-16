import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "membership_selection.g.dart";

/// The roles each pending join request is granted once accepted, chosen in
/// the inspector. A request nobody chose roles for is granted none and
/// cannot be accepted yet.
@Riverpod(keepAlive: true)
class JoinRequestGrants extends _$JoinRequestGrants {
  @override
  Map<skir.RecordId, Set<skir.RecordId>> build() {
    return const {};
  }

  /// Sets the roles granted to each request in [grants].
  void grant(Map<skir.RecordId, Set<skir.RecordId>> grants) {
    state = {...state, ...grants};
  }

  /// Forgets the grants of [requests], once they are accepted or declined.
  void forget(Iterable<skir.RecordId> requests) {
    final gone = requests.toSet();
    state = {
      for (final entry in state.entries)
        if (!gone.contains(entry.key)) entry.key: entry.value,
    };
  }
}

/// Selection identity of one organization member.
final class MemberIdentifier extends SelectableIdentifier {
  const MemberIdentifier(this.userId);

  final skir.RecordId userId;

  @override
  String get id => "member:${userId.id}";

  @override
  Object get resourceId => userId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final members = ref.watch(organizationMembersProvider);
    if (members.mapUnready<Selectable>() case final unready?) return unready;
    final member = members.requireValue.firstWhereOrNull(
      (member) => member.userId == userId,
    );
    if (member == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    return AsyncData(MemberSelectable(id: this, member: member));
  }

  @override
  int get hashCode => Object.hash(MemberIdentifier, userId);

  @override
  bool operator ==(Object other) =>
      other is MemberIdentifier && other.userId == userId;

  @override
  String toString() => "MemberIdentifier($userId)";
}

/// One member as the inspector shows it: their details and the roles they
/// hold. Several members share one roles field.
final class MemberSelectable extends InspectableSelectable<MemberIdentifier> {
  const MemberSelectable({required this.id, required this.member});

  @override
  final MemberIdentifier id;
  final skir.OrganizationMember member;

  @override
  String get name => member.name ?? member.email ?? "Member";

  @override
  SelectableNoun get noun =>
      const SelectableNoun(one: "member", many: "members");

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  List<SharedInspectionSurface> get sharedInspectionSurfaces => [
    _MemberRolesSurface(member),
  ];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) {
    return InspectionContent(body: MemberInspection(members: [member]));
  }
}

final class _MemberRolesSurface implements SharedInspectionSurface {
  const _MemberRolesSurface(this.member);

  final skir.OrganizationMember member;

  @override
  Object get id => "member.roles";

  @override
  bool isCompatibleWith(SharedInspectionSurface other) =>
      other is _MemberRolesSurface;

  @override
  InspectionContent buildShared(
    List<SharedInspectionSurface> members,
    InspectionBuildContext context,
  ) {
    return InspectionContent(
      body: MemberInspection(
        members: [
          for (final surface in members.cast<_MemberRolesSurface>())
            surface.member,
        ],
      ),
    );
  }
}

/// Selection identity of one active join code.
final class JoinCodeIdentifier extends SelectableIdentifier {
  const JoinCodeIdentifier(this.codeId);

  final skir.RecordId codeId;

  @override
  String get id => "join_code:${codeId.id}";

  @override
  Object get resourceId => codeId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final codes = ref.watch(visibleOrganizationJoinCodesProvider);
    if (codes.mapUnready<Selectable>() case final unready?) return unready;
    final code = codes.requireValue.firstWhereOrNull(
      (code) => code.code == codeId,
    );
    if (code == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    final roles = ref.watch(organizationRolesProvider).value ?? const [];
    return AsyncData(
      JoinCodeSelectable(
        id: this,
        code: code,
        roles: [
          for (final role in roles)
            if (code.autoAccept.roleIds.contains(role.roleId)) role,
        ],
      ),
    );
  }

  @override
  int get hashCode => Object.hash(JoinCodeIdentifier, codeId);

  @override
  bool operator ==(Object other) =>
      other is JoinCodeIdentifier && other.codeId == codeId;

  @override
  String toString() => "JoinCodeIdentifier($codeId)";
}

/// One join code as the inspector shows it: its link, the roles it grants
/// straight away, how often it works and when it expires.
final class JoinCodeSelectable
    extends InspectableSelectable<JoinCodeIdentifier> {
  const JoinCodeSelectable({
    required this.id,
    required this.code,
    required this.roles,
  });

  @override
  final JoinCodeIdentifier id;
  final skir.JoinCode code;

  /// The roles a newcomer is granted without approval; empty when their
  /// request waits for approval.
  final List<skir.OrganizationRole> roles;

  @override
  String get name => "Join code";

  @override
  SelectableNoun get noun =>
      const SelectableNoun(one: "join code", many: "join codes");

  @override
  List<SelectionCapability> get capabilities => [
    CopySelectionCapability(joinCodeUrl(code.code)),
  ];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) {
    return InspectionContent(
      body: JoinCodeInspection(code: code, roles: roles),
    );
  }
}

/// Selection identity of one pending join request.
final class JoinRequestIdentifier extends SelectableIdentifier {
  const JoinRequestIdentifier(this.requestId);

  final skir.RecordId requestId;

  @override
  String get id => "join_request:${requestId.id}";

  @override
  Object get resourceId => requestId;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final requests = ref.watch(visibleOrganizationJoinRequestsProvider);
    if (requests.mapUnready<Selectable>() case final unready?) return unready;
    final request = requests.requireValue.firstWhereOrNull(
      (request) => request.requestId == requestId,
    );
    if (request == null) {
      return AsyncError(SelectableNotFoundException(this), StackTrace.current);
    }
    return AsyncData(
      JoinRequestSelectable(
        id: this,
        request: request,
        grant: ref.watch(
          joinRequestGrantsProvider.select(
            (grants) => grants[requestId] ?? const {},
          ),
        ),
      ),
    );
  }

  @override
  int get hashCode => Object.hash(JoinRequestIdentifier, requestId);

  @override
  bool operator ==(Object other) =>
      other is JoinRequestIdentifier && other.requestId == requestId;

  @override
  String toString() => "JoinRequestIdentifier($requestId)";
}

/// One pending join request as the inspector shows it: who asks and the
/// roles they are granted once accepted. Several requests share one roles
/// field.
final class JoinRequestSelectable
    extends InspectableSelectable<JoinRequestIdentifier> {
  const JoinRequestSelectable({
    required this.id,
    required this.request,
    required this.grant,
  });

  @override
  final JoinRequestIdentifier id;
  final skir.OrganizationJoinRequest request;

  /// The ids of the roles the request is granted once accepted.
  final Set<skir.RecordId> grant;

  @override
  String get name => request.userName ?? request.userEmail ?? "Join request";

  @override
  SelectableNoun get noun =>
      const SelectableNoun(one: "join request", many: "join requests");

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  List<SharedInspectionSurface> get sharedInspectionSurfaces => [
    _JoinRequestGrantSurface(this),
  ];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) {
    return InspectionContent(body: JoinRequestInspection(requests: [this]));
  }
}

final class _JoinRequestGrantSurface implements SharedInspectionSurface {
  const _JoinRequestGrantSurface(this.request);

  final JoinRequestSelectable request;

  @override
  Object get id => "join_request.grant";

  @override
  bool isCompatibleWith(SharedInspectionSurface other) =>
      other is _JoinRequestGrantSurface;

  @override
  InspectionContent buildShared(
    List<SharedInspectionSurface> members,
    InspectionBuildContext context,
  ) {
    return InspectionContent(
      body: JoinRequestInspection(
        requests: [
          for (final surface in members.cast<_JoinRequestGrantSurface>())
            surface.request,
        ],
      ),
    );
  }
}
