/// The authenticated session and the route scope it applies to: identity
/// provider state, the signed in user, and the organization and realm the
/// current route selects. Messaging and local work depend on it, so it sits
/// below them.
library;

export "auth.dart";
export "organization_scope.dart";
export "route_scope.dart";
