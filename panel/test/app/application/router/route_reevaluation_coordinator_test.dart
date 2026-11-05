import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  late RouteAccessCoordinator access;
  late RouteReevaluationCoordinator coordinator;
  late HeldReevaluations reevaluations;

  setUp(() {
    access = RouteAccessCoordinator(
      authentication: AuthenticationRouteAccess()
        ..setDecision(const RouteAuthenticationDecision.authenticated()),
      organizations: OrganizationRouteAccess(),
    );
    reevaluations = HeldReevaluations();
    coordinator = RouteReevaluationCoordinator(
      access: access,
      reevaluateGuards: reevaluations.call,
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

    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, isEmpty);
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

    expect(reevaluations.calls, hasLength(1));
    reevaluations.calls.single.complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(1));
  });

  test("serializes and coalesces a notification burst", () async {
    access.authentication.flip();
    access.authentication.flip();
    access.authentication.flip();
    expect(reevaluations.calls, hasLength(1));

    reevaluations.calls[0].complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(2));
    expect(reevaluations.maximumActive, 1);

    reevaluations.calls[1].complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(2));
    expect(reevaluations.maximumActive, 1);
  });

  test("notification during a follow up schedules one later call", () async {
    access.authentication.flip();
    access.authentication.flip();
    reevaluations.calls[0].complete();
    await Future<void>.delayed(Duration.zero);

    access.authentication.flip();
    access.authentication.flip();
    reevaluations.calls[1].complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(3));
    expect(reevaluations.maximumActive, 1);

    reevaluations.calls[2].complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(3));
  });

  test("reports errors and continues pending and later work", () async {
    final previousOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    access.authentication.flip();
    access.authentication.flip();
    reevaluations.calls[0].completeError(StateError("failed"));
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(1));
    expect(reevaluations.calls, hasLength(2));

    reevaluations.calls[1].complete();
    await Future<void>.delayed(Duration.zero);
    access.authentication.flip();
    expect(reevaluations.calls, hasLength(3));
    reevaluations.calls[2].complete();
  });

  test("dispose during active work suppresses follow ups", () async {
    access.authentication.flip();
    access.authentication.flip();
    coordinator.dispose();
    reevaluations.calls[0].complete();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(1));

    access.authentication.flip();
    await Future<void>.delayed(Duration.zero);
    expect(reevaluations.calls, hasLength(1));
  });

  test("dispose is idempotent and post-dispose notifications do nothing", () {
    coordinator
      ..dispose()
      ..dispose();
    access.authentication.flip();
    expect(reevaluations.calls, isEmpty);
  });
}
