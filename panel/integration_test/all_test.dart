import "access_test.dart" as access;
import "authoring_test.dart" as authoring;
import "connection_test.dart" as connection;
import "membership_test.dart" as membership;
import "publishing_test.dart" as publishing;
import "support/scenarios.dart";

/// The one `flutter drive` target: `flutter drive` accepts a single target per
/// run, so every scenario group registers here.
void main() => runScenarios([
  access.main, // AUTH-1, REALM-1, REALM-1.E1, ORG-1
  membership.main, // JOIN-1, JOIN-1.E1, JOIN-1.E2, MEMBER-1
  authoring
      .main, // BOOK-1, BOOK-3, PAGE-1, LINK-1, SEARCH-1, GUARD-1, CONFLICT-1
  publishing.main, // PUB-1, PUB-1.E1
  connection.main, // CONN-1
]);
