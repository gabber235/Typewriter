import "package:typewriter_panel/typewriter_panel.dart";

part "organization_route_access.freezed.dart";

/// Snapshot of the authenticated principal's organization access.
///
/// Loading and unavailable states are intentionally distinct from an available
/// empty set. The latter means access data loaded successfully and the user is
/// not a member of any organization.
@freezed
sealed class OrganizationRouteAccessState with _$OrganizationRouteAccessState {
  const factory OrganizationRouteAccessState.loading() =
      OrganizationRouteAccessLoading;
  const factory OrganizationRouteAccessState.unavailable() =
      OrganizationRouteAccessUnavailable;
  const factory OrganizationRouteAccessState.available({
    required String? principalId,
    required Set<String> organizationIds,
  }) = OrganizationRouteAccessAvailable;
}

/// Decision for one organization route parameter.
enum OrganizationRouteDecision { loading, member, nonMember, unavailable }

/// Owns the organization membership snapshot consumed by route guards.
///
/// The available state is the stable authorization fact. The principal and
/// membership set are replaced together by the binding, so a route is checked
/// against one coherent observation rather than two independently changing
/// providers.
final class OrganizationRouteAccess implements RouteAccessModule {
  OrganizationRouteAccess()
    : _state = RouteAccessStateController(
        initialState: const OrganizationRouteAccessState.loading(),
        isPending: (state) => state is OrganizationRouteAccessLoading,
        stableStateOf: (state) => switch (state) {
          OrganizationRouteAccessAvailable() => state,
          OrganizationRouteAccessLoading() ||
          OrganizationRouteAccessUnavailable() => null,
        },
      );

  final RouteAccessStateController<
    OrganizationRouteAccessState,
    OrganizationRouteAccessAvailable
  >
  _state;
  bool _disposed = false;

  OrganizationRouteAccessState get state => _state.current;

  /// Publishes a new coherent principal and membership observation.
  void setState(OrganizationRouteAccessState state) =>
      _state.transitionTo(state);

  /// Maps a route organization identifier to the guard's decision.
  OrganizationRouteDecision decisionFor(String organizationId) =>
      switch (_state.current) {
        OrganizationRouteAccessLoading() => OrganizationRouteDecision.loading,
        OrganizationRouteAccessUnavailable() =>
          OrganizationRouteDecision.unavailable,
        OrganizationRouteAccessAvailable(:final organizationIds) =>
          organizationIds.contains(organizationId)
              ? OrganizationRouteDecision.member
              : OrganizationRouteDecision.nonMember,
      };

  @override
  Listenable get reevaluation => _state.reevaluation;

  @override
  Future<void> waitUntilReady() => _state.waitUntilReady();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state
      ..transitionTo(const OrganizationRouteAccessState.unavailable())
      ..dispose();
  }
}
