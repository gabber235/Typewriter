import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The organizations, realms and services a test world's backend knows.
///
/// Replaces the three organization projections the panel watches over NATS:
/// the user's organization list, each organization's topology and its
/// services. Every realm runs on its own host whose service keeps reporting,
/// so the realm counts as online until a test takes the connection away. It
/// remembers changes made through it and holds no service rules.
final class FakeOrganizations {
  FakeOrganizations();

  final _members = <String, List<skir.Organization>>{};
  final _realms = <skir.RecordId, List<skir.RealmInstance>>{};
  final _changes = StreamController<void>.broadcast(sync: true);
  final _stopped = <skir.RecordId>{};

  /// Makes [user] a member of [organization].
  void join(String user, skir.Organization organization) {
    final organizations = _members.putIfAbsent(user, () => []);
    if (organizations.any(
      (existing) => existing.organizationId == organization.organizationId,
    )) {
      return;
    }
    organizations.add(organization);
    _changes.add(null);
  }

  /// Removes [user] from the organization [organization], the way an
  /// administrator removing a member does.
  void leave(String user, skir.RecordId organization) {
    _members[user]?.removeWhere(
      (existing) => existing.organizationId == organization,
    );
    _changes.add(null);
  }

  /// The organizations [user] belongs to.
  List<skir.Organization> of(String user) => [...?_members[user]];

  /// Adds a realm named [name] with [id] to [organization], hosted on a
  /// connected server.
  skir.RealmInstance addRealm(
    skir.RecordId organization, {
    required skir.RecordId id,
    required String name,
  }) {
    final realm = skir.RealmInstance(
      realmId: id,
      ownerHost: skir.OwnerHost(
        id: skir.recordId("service_host:${id.id}"),
        name: name,
      ),
      revision: 1,
      targetEngine: skir.EngineTarget(
        engineId: "typewritermc:paper",
        versionConstraint: "*",
      ),
      state: skir.ChildRuntimeState(
        status: skir.ChildRuntimeStatus.active,
        activeArtifactVersion: "1.0.0",
        message: null,
        updatedAt: clock.now(),
      ),
    );
    _realms.putIfAbsent(organization, () => []).add(realm);
    _changes.add(null);
    return realm;
  }

  /// The host of [realm] stops reporting, so the panel sees the Realm
  /// offline.
  void stopHost(skir.RecordId realm) {
    _stopped.add(realm);
    _changes.add(null);
  }

  /// The host of [realm] reports again after [stopHost], so the panel sees
  /// the Realm back online.
  void resumeHost(skir.RecordId realm) {
    _stopped.remove(realm);
    _changes.add(null);
  }

  /// The topology of [organization]: its realms and the hosts running them.
  skir.OrganizationTopologySnapshot topology(skir.RecordId organization) {
    final realms = [...?_realms[organization]];
    return skir.OrganizationTopologySnapshot(
      realms: realms,
      engines: const [],
      hosts: [
        for (final realm in realms)
          skir.ServiceHost(
            hostId: realm.ownerHost.id,
            serviceId: _serviceOf(realm),
            revision: 1,
            entrypoint: "PAPER",
            canHostRealm: true,
            supportedEngines: const [],
            topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
            state: skir.HostRuntimeState(
              status: skir.HostRuntimeStatus.active,
              message: null,
              updatedAt: realm.state.updatedAt,
            ),
          ),
      ],
    );
  }

  /// The services of [organization]; each running one reported in just now.
  List<skir.Service> services(skir.RecordId organization) => [
    for (final realm in [...?_realms[organization]])
      skir.Service(
        serviceId: _serviceOf(realm),
        revision: 1,
        name: realm.ownerHost.name,
        role: skir.ServiceRole.createHost(version: "1.0.0"),
        createdAt: realm.state.updatedAt,
        state: skir.ServiceState(
          status: _stopped.contains(realm.realmId)
              ? skir.ServiceStatus.offline
              : skir.ServiceStatus.online,
          lastSeen: clock.now(),
        ),
        organization: null,
        registration: null,
      ),
  ];

  skir.RecordId _serviceOf(skir.RealmInstance realm) =>
      skir.recordId("service:${realm.realmId.id}");

  /// Replaces the organization list, topology and services projections, and
  /// the user's own join requests, of which there are none.
  List<Override> get overrides => [
    organizationsProvider.overrideWith(() => _Organizations(this)),
    userJoinRequestsProvider.overrideWith(_NoJoinRequests.new),
    organizationTopologyControllerProvider.overrideWith2(
      (_) => _Topology(this),
    ),
    canonicalOrganizationServicesProvider.overrideWith2((_) => _Services(this)),
  ];

  /// Ends every open projection.
  Future<void> close() => _changes.close();
}

final class _NoJoinRequests extends UserJoinRequests {
  @override
  Stream<List<skir.UserJoinRequest>> build() => Stream.value(const []);
}

final class _Organizations extends Organizations {
  _Organizations(this._backend);

  final FakeOrganizations _backend;

  @override
  Stream<List<skir.Organization>> build() =>
      ref.watchSignedIn(signedOut: const [], (user) async* {
        yield _backend.of(user);
        yield* _backend._changes.stream.map((_) => _backend.of(user));
      });
}

final class _Topology extends OrganizationTopologyController {
  _Topology(this._backend);

  final FakeOrganizations _backend;

  @override
  Stream<skir.OrganizationTopologySnapshot> build(
    skir.RecordId organizationId,
  ) async* {
    yield _backend.topology(organizationId);
    yield* _backend._changes.stream.map(
      (_) => _backend.topology(organizationId),
    );
  }
}

final class _Services extends CanonicalOrganizationServices {
  _Services(this._backend);

  final FakeOrganizations _backend;

  @override
  Stream<List<skir.Service>> build(skir.RecordId organizationId) async* {
    yield _backend.services(organizationId);
    yield* _backend._changes.stream.map(
      (_) => _backend.services(organizationId),
    );
  }
}
