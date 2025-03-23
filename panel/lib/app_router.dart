import "package:auto_route/auto_route.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/app_router.gr.dart";
import "package:typewriter_panel/logic/auth.dart";

part "app_router.g.dart";

@riverpod
Raw<AppRouter> appRouter(Ref ref) => AppRouter(ref);

@AutoRouterConfig(replaceInRouteName: "Page,Route")
class AppRouter extends RootStackRouter {
  AppRouter(this.ref);

  final Ref ref;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: AuthRoute.page,
          path: "/auth",
          keepHistory: false,
          maintainState: false,
        ),
        AutoRoute(
          page: HomeRoute.page,
          path: "/",
          initial: true,
          guards: [AuthGuard(ref)],
          keepHistory: false,
          maintainState: false,
        ),
      ];
}

class AuthGuard extends AutoRouteGuard {
  const AuthGuard(this.ref);
  final Ref ref;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuthenticated = ref.read(isAuthenticatedProvider).requireValue;

    if (isAuthenticated) {
      resolver.next();
      return;
    }

    resolver.redirectUntil(
      AuthRoute(
        onResult: (isAuthenticated) {
          resolver.next(isAuthenticated);
        },
      ),
    );
  }
}
