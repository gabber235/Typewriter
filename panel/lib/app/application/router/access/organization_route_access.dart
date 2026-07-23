import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/app/application/router/access/route_access_module.dart";
import "package:typewriter_panel/app/application/router/access/route_access_state_controller.dart";

part "organization_route_access.freezed.dart";

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

enum OrganizationRouteDecision { loading, member, nonMember, unavailable }

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

  void setState(OrganizationRouteAccessState state) =>
      _state.transitionTo(state);

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
