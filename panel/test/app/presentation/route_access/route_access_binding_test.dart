// ignore_for_file: invalid_use_of_internal_member

import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/legacy.dart";
import "package:typewriter_panel/app/application/router/access/authentication_route_access.dart";
import "package:typewriter_panel/app/application/router/access/organization_route_access.dart";
import "package:typewriter_panel/app/application/router/access/route_access_coordinator.dart";
import "package:typewriter_panel/app/presentation/route_access/authentication_route_access_binding.dart";
import "package:typewriter_panel/app/presentation/route_access/organization_route_access_binding.dart";
import "package:typewriter_panel/app/presentation/route_access/route_access_binding.dart";
import "package:typewriter_panel/features/auth/application/auth.dart";
import "package:typewriter_panel/features/organizations/application/application.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";

final _authenticationDependency = StateProvider<Future<bool>>(
  (ref) => Future.value(false),
);
final _principalDependency = StateProvider<Future<String?>>(
  (ref) => Future.value(null),
);
final _organizationsDependency = StateProvider<Stream<List<OrganizationData>>>(
  (ref) => const Stream.empty(),
);

final class _ControlledOrganizations extends Organizations {
  @override
  Stream<List<OrganizationData>> build() => ref.watch(_organizationsDependency);
}

RouteAccessCoordinator _coordinator() => RouteAccessCoordinator(
  authentication: AuthenticationRouteAccess(),
  organizations: OrganizationRouteAccess(),
);

OrganizationData _organization(String id) => OrganizationData(
  organizationId: recordId("organization:$id"),
  name: id,
  logoUrl: "",
);

Widget _app({required RouteAccessCoordinator access, required Widget child}) {
  return ProviderScope(
    overrides: [
      isAuthenticatedProvider.overrideWith(
        (ref) => ref.watch(_authenticationDependency),
      ),
      userIdProvider.overrideWith((ref) => ref.watch(_principalDependency)),
      organizationsProvider.overrideWith(_ControlledOrganizations.new),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: RouteAccessBinding(access: access, builder: (_) => child),
    ),
  );
}

void main() {
  testWidgets("fireImmediately seeds modules before builder", (tester) async {
    final access = _coordinator();
    late RouteAuthenticationDecision authentication;
    late OrganizationRouteDecision organization;

    await tester.pumpWidget(
      _app(
        access: access,
        child: Builder(
          builder: (context) {
            authentication = access.authentication.decision;
            organization = access.organizations.decisionFor("missing");
            return const SizedBox();
          },
        ),
      ),
    );

    expect(authentication, const RouteAuthenticationDecision.loading());
    expect(organization, OrganizationRouteDecision.loading);
    access.dispose();
  });

  test("mapping prioritizes loading and errors over retained data", () {
    const retained = AsyncData(true);
    final loading = const AsyncLoading<bool>().copyWithPrevious(retained);
    final error = AsyncError<bool>(
      StateError("failed"),
      StackTrace.empty,
    ).copyWithPrevious(retained);

    expect(
      authenticationRouteDecision(loading),
      isA<RouteAuthenticationLoading>(),
    );
    expect(
      organizationRouteAccessState(
        const AsyncLoading<String?>().copyWithPrevious(const AsyncData("old")),
        AsyncData([_organization("old")]),
      ),
      isA<OrganizationRouteAccessLoading>(),
    );
    expect(
      organizationRouteAccessState(
        const AsyncData("user"),
        AsyncError<List<OrganizationData>>(
          StateError("failed"),
          StackTrace.empty,
        ).copyWithPrevious(AsyncData([_organization("old")])),
      ),
      isA<OrganizationRouteAccessUnavailable>(),
    );
    final authentication = AuthenticationRouteAccess()
      ..setDecision(authenticationRouteDecision(error));
    expect(
      authentication.decision,
      const RouteAuthenticationDecision.unavailable(),
    );
    authentication.dispose();
  });

  testWidgets("session switch never exposes stale membership", (tester) async {
    final oldOrganizations = StreamController<List<OrganizationData>>(
      sync: true,
    );
    final access = _coordinator();
    await tester.pumpWidget(_app(access: access, child: const SizedBox()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    container.read(_principalDependency.notifier).state = Future.value(
      "user-1",
    );
    await tester.pump();
    container.read(_organizationsDependency.notifier).state =
        oldOrganizations.stream;
    await tester.pump();
    oldOrganizations.add([_organization("old")]);
    await tester.pump();
    await tester.pump();
    expect(
      access.organizations.decisionFor("old"),
      OrganizationRouteDecision.member,
    );

    final user2 = Completer<String?>();
    final newOrganizations = StreamController<List<OrganizationData>>(
      sync: true,
    );
    container.read(_principalDependency.notifier).state = user2.future;
    container.read(_organizationsDependency.notifier).state =
        newOrganizations.stream;
    await tester.pump();
    expect(
      access.organizations.decisionFor("old"),
      OrganizationRouteDecision.loading,
    );

    user2.complete("user-2");
    await tester.pump();
    await tester.pump();
    expect(
      access.organizations.decisionFor("old"),
      OrganizationRouteDecision.loading,
    );
    newOrganizations.add([_organization("new")]);
    await tester.pump();
    expect(
      access.organizations.decisionFor("old"),
      OrganizationRouteDecision.nonMember,
    );
    expect(
      access.organizations.decisionFor("new"),
      OrganizationRouteDecision.member,
    );

    access.dispose();
  });

  testWidgets("organization loading before principal loading resolves", (
    tester,
  ) async {
    final organizations = StreamController<List<OrganizationData>>(sync: true);
    final principal = Completer<String?>();
    final access = _coordinator();
    await tester.pumpWidget(_app(access: access, child: const SizedBox()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    container.read(_organizationsDependency.notifier).state =
        organizations.stream;
    await tester.pump();
    container.read(_principalDependency.notifier).state = principal.future;
    await tester.pump();
    principal.complete("user");
    await tester.pump();
    organizations.add([_organization("new")]);
    await tester.pump();
    await tester.pump();

    expect(
      access.organizations.decisionFor("new"),
      OrganizationRouteDecision.member,
    );
    access.dispose();
  });

  testWidgets("unmount closes subscriptions", (tester) async {
    final access = _coordinator();
    final mounted = StateProvider((ref) => true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith(
            (ref) => ref.watch(_authenticationDependency),
          ),
          userIdProvider.overrideWith((ref) => ref.watch(_principalDependency)),
          organizationsProvider.overrideWith(_ControlledOrganizations.new),
        ],
        child: Consumer(
          builder: (context, ref, _) => ref.watch(mounted)
              ? RouteAccessBinding(
                  access: access,
                  builder: (_) => const SizedBox(),
                )
              : const SizedBox(),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    final decisionAtUnmount = access.authentication.decision;
    container.read(mounted.notifier).state = false;
    await tester.pump();

    container.read(_authenticationDependency.notifier).state = Future.value(
      true,
    );
    await tester.pump();
    expect(access.authentication.decision, decisionAtUnmount);
    access.dispose();
  });

  testWidgets("coordinator replacement rebinds and detaches old coordinator", (
    tester,
  ) async {
    final oldAccess = _coordinator();
    final newAccess = _coordinator();
    await tester.pumpWidget(_app(access: oldAccess, child: const SizedBox()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    final oldDecision = oldAccess.authentication.decision;
    await tester.pumpWidget(_app(access: newAccess, child: const SizedBox()));

    container.read(_authenticationDependency.notifier).state = Future.value(
      true,
    );
    await tester.pump();
    expect(oldAccess.authentication.decision, oldDecision);
    expect(
      newAccess.authentication.decision,
      const RouteAuthenticationDecision.authenticated(),
    );
    oldAccess.dispose();
    newAccess.dispose();
  });

  testWidgets("provider callbacks can synchronously notify coordinator", (
    tester,
  ) async {
    final access = _coordinator();
    var notifications = 0;
    access.addListener(() => notifications++);

    await tester.pumpWidget(_app(access: access, child: const SizedBox()));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    container.read(_authenticationDependency.notifier).state = Future.value(
      true,
    );
    await tester.pump();

    expect(notifications, greaterThan(0));
    expect(tester.takeException(), isNull);
    access.dispose();
  });
}
