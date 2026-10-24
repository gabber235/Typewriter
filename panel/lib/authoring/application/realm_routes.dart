import "package:typewriter_panel/typewriter_panel.dart";

part "realm_routes.g.dart";

/// The routes that show a realm's authoring surfaces.
///
/// Authoring decides which surface to open; the realms feature owns the route
/// tree that shows it. Authoring asks this interface for the route instead of
/// building the application's typed routes itself.
abstract interface class RealmRoutes {
  /// The realm route of [scope], showing the realm's default page.
  PageRouteInfo<Object?> realm(AuthoringScope scope);

  /// The route that shows [target] in [scope].
  PageRouteInfo<Object?> surface(AuthoringScope scope, SurfaceTarget target);
}

/// The realm routes for authoring.
///
/// The app installs the realms feature's routes through appOverrides; reading
/// it without the app is a wiring error.
@Riverpod(keepAlive: true)
RealmRoutes realmRoutes(Ref ref) => throw UnimplementedError(
  "realmRoutesProvider is installed by appOverrides",
);
