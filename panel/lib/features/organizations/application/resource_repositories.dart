import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_repositories.g.dart";

/// Provides one resource repository owner for the active local work scope.
///
/// The owner retains its repositories across authenticated transport replacement
/// and rebinds their active watches. Scope disposal cascades to every cached child.
@Riverpod(keepAlive: true)
ResourceRepositories resourceRepositories(Ref ref) {
  ref.watch(localWorkScopeProvider);
  final connection = ref.watch(natsProvider.notifier);
  final telemetry = ref.watch(panelTelemetryProvider.future);
  final repositories = ResourceRepositories(
    SkirMutationClient(() => connection.client, () => telemetry),
    ref.watch(userIdProvider).value,
    admitAuthoringRealms: connection.ensureRealmsAdmitted,
  );
  ref
    ..listen(natsProvider, (previous, next) {
      if (previous == null || identical(previous, next)) return;
      unawaited(
        repositories.rebindTransport(next).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: "authoring transport",
              context: ErrorDescription("rebinding retained authoring watches"),
            ),
          );
        }),
      );
    })
    ..onDispose(repositories.dispose);
  return repositories;
}

/// Organization scoped factory and lifetime owner for resource repositories.
///
/// The provider creates one instance for the active local work scope and disposes
/// every cached child when that scope ends. Authoring children may own network
/// watches while their route session is active, so that session must release its
/// child when it ends.
final class ResourceRepositories {
  ResourceRepositories(
    this.transport,
    this.userId, {
    Future<void> Function(Set<skir.RecordId>)? admitAuthoringRealms,
  }) : _admitAuthoringRealms = admitAuthoringRealms ?? ((_) async {});
  final SkirMutationClient transport;
  final String? userId;
  final Future<void> Function(Set<skir.RecordId>) _admitAuthoringRealms;
  final _services = <skir.RecordId, ServiceResourceRepository>{};
  final _authoring =
      <(skir.RecordId, skir.RecordId), AuthoringResourceRepository>{};
  final _memberships = <skir.RecordId, MembershipResourceRepository>{};
  bool _disposed = false;

  /// Fails fast when a child repository is requested after scope disposal.
  void checkActive() {
    if (_disposed) throw StateError("The resource session ended");
  }

  String requireUserId() {
    checkActive();
    return userId ?? (throw ApiException.notAuthenticated());
  }

  Future<void> ensureAuthoringRealmsAdmitted(Set<skir.RecordId> realms) {
    checkActive();
    return _admitAuthoringRealms(realms);
  }

  /// Returns the shared membership command owner for one organization.
  MembershipResourceRepository membership(skir.RecordId organization) {
    checkActive();
    return _memberships.putIfAbsent(
      organization,
      () => MembershipResourceRepository(this, organization),
    );
  }

  Future<void> rebindTransport(NatsClient client) async {
    if (_disposed) return;
    final retained = _authoring.values.toList(growable: false);
    await Future.wait(
      retained.map((repository) => repository.rebindTransport(client)),
    );
  }

  /// Returns the cached services repository for one organization.
  ///
  /// Repeated calls share the repository and therefore its mutation boundary.
  ServiceResourceRepository services(skir.RecordId organization) {
    checkActive();
    return _services.putIfAbsent(
      organization,
      () => ServiceResourceRepository(this, organization),
    );
  }

  /// Returns the cached authoring repository for one organization and realm.
  ///
  /// The realm is part of the cache key because authoring operations are scoped
  /// more narrowly than organization level service operations.
  AuthoringResourceRepository authoring(
    skir.RecordId organization,
    skir.RecordId realm,
  ) {
    checkActive();
    return _authoring.putIfAbsent((
      organization,
      realm,
    ), () => AuthoringResourceRepository(this, organization, realm));
  }

  /// Returns every Realm whose retained authoring repository needs transport.
  Set<skir.RecordId> authoringRealms(skir.RecordId organization) =>
      Set<skir.RecordId>.unmodifiable(
        _authoring.keys
            .where((scope) => scope.$1 == organization)
            .map((scope) => scope.$2),
      );

  /// Releases the exact authoring repository owned by a route session.
  ///
  /// Removing it from the cache before disposal ensures a later session receives
  /// fresh transfer cancellation state and fresh network watches. Identity keeps
  /// a stale release from evicting a newer session repository for the same Realm.
  void releaseAuthoring(AuthoringResourceRepository repository) {
    final key = (repository.organization, repository.realm);
    if (identical(_authoring[key], repository)) {
      _authoring.remove(key);
    }
    repository.dispose();
  }

  /// Ends the resource scope and disposes every repository created by this owner.
  void dispose() {
    _disposed = true;
    for (final repository in _services.values) {
      repository.dispose();
    }
    for (final repository in _authoring.values) {
      repository.dispose();
    }
    for (final repository in _memberships.values) {
      repository.dispose();
    }
    _memberships.clear();
    _services.clear();
    _authoring.clear();
  }
}
