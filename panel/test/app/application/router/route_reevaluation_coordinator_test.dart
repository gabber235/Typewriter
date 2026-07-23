import "dart:async";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/app/application/router/access/authentication_route_access.dart";
import "package:typewriter_panel/app/application/router/access/organization_route_access.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";
import "package:typewriter_panel/app/application/router/route_reevaluation_coordinator.dart";

void main() {
  late RouteAccessCoordinator access;
  late RouteReevaluationCoordinator coordinator;
  late List<Completer<void>> calls;
  late int active;
  late int maximumActive;

  Future<void> reevaluate() {
    active++;
    maximumActive = max(maximumActive, active);
    final call = Completer<void>();
    calls.add(call);
    return call.future.whenComplete(() => active--);
  }

  void notify() {
    final decision =
        access.authentication.decision is RouteAuthenticationAuthenticated
        ? const RouteAuthenticationDecision.unauthenticated()
        : const RouteAuthenticationDecision.authenticated();
    access.authentication.setDecision(decision);
  }

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    access = RouteAccessCoordinator(
      authentication: AuthenticationRouteAccess()
        ..setDecision(const RouteAuthenticationDecision.authenticated()),
      organizations: OrganizationRouteAccess(),
    );
    calls = [];
    active = 0;
    maximumActive = 0;
    coordinator = RouteReevaluationCoordinator(
      access: access,
      reevaluateGuards: reevaluate,
    );
  });

  tearDown(() {
    coordinator.dispose();
    access.dispose();
  });

  test("identical organization recovery causes no reevaluation", () async {
    access.organizations
      ..setState(
        OrganizationRouteAccessState.available(
          principalId: "user",
          organizationIds: {"a", "other"},
        ),
      )
      ..setState(const OrganizationRouteAccessState.loading())
      ..setState(const OrganizationRouteAccessState.unavailable())
      ..setState(
        OrganizationRouteAccessState.available(
          principalId: "user",
          organizationIds: {"other", "a"},
        ),
      );

    await flush();
    expect(calls, isEmpty);
  });

  test("changed organization recovery causes one reevaluation", () async {
    access.organizations
      ..setState(
        OrganizationRouteAccessState.available(
          principalId: "user",
          organizationIds: {"a", "other"},
        ),
      )
      ..setState(const OrganizationRouteAccessState.loading())
      ..setState(const OrganizationRouteAccessState.unavailable())
      ..setState(
        OrganizationRouteAccessState.available(
          principalId: "user",
          organizationIds: {"b", "other"},
        ),
      );

    expect(calls, hasLength(1));
    calls.single.complete();
    await flush();
    expect(calls, hasLength(1));
  });

  test("serializes and coalesces a notification burst", () async {
    notify();
    notify();
    notify();
    expect(calls, hasLength(1));

    calls[0].complete();
    await flush();
    expect(calls, hasLength(2));
    expect(maximumActive, 1);

    calls[1].complete();
    await flush();
    expect(calls, hasLength(2));
    expect(maximumActive, 1);
  });

  test("notification during a follow up schedules one later call", () async {
    notify();
    notify();
    calls[0].complete();
    await flush();

    notify();
    notify();
    calls[1].complete();
    await flush();
    expect(calls, hasLength(3));
    expect(maximumActive, 1);

    calls[2].complete();
    await flush();
    expect(calls, hasLength(3));
  });

  test("reports errors and continues pending and later work", () async {
    final previousOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    notify();
    notify();
    calls[0].completeError(StateError("failed"));
    await flush();
    expect(errors, hasLength(1));
    expect(calls, hasLength(2));

    calls[1].complete();
    await flush();
    notify();
    expect(calls, hasLength(3));
    calls[2].complete();
  });

  test("dispose during active work suppresses follow ups", () async {
    notify();
    notify();
    coordinator.dispose();
    calls[0].complete();
    await flush();
    expect(calls, hasLength(1));

    notify();
    await flush();
    expect(calls, hasLength(1));
  });

  test("dispose is idempotent and post-dispose notifications do nothing", () {
    coordinator
      ..dispose()
      ..dispose();
    notify();
    expect(calls, isEmpty);
  });
}
