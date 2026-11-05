/// The stack a scenario runs against: its fixture users and its fault switches.
///
/// `cargo xtask e2e` passes the target's `panel.json` through
/// `--dart-define-from-file`, so every value here is a compile time define.
/// The worktree stack and the CI cluster both name their users and their
/// faults links, so every scenario runs on both.
///
/// Import with a prefix (`import "support/stack.dart" as stack;`), so calls
/// read as `stack.natsLink(enabled: false)`.
library;

import "dart:convert";

import "package:http/http.dart" as http;
import "package:typewriter_panel/typewriter_panel.dart" show kIsWeb;

const _faults = String.fromEnvironment("STACK_FAULTS_URL");
const _users = String.fromEnvironment("STACK_USERS", defaultValue: "[]");

/// The faults link the panel's NATS connection goes through: the web panel
/// connects over websockets, so it has its own.
const _panelLink = kIsWeb ? "nats-web" : "nats";

/// A fixture user the target's identity provider accepts with the password
/// grant.
class StackUser {
  const StackUser({
    required this.username,
    required this.password,
    required this.organizations,
  });

  factory StackUser.fromJson(Map<String, Object?> json) => StackUser(
    username: json["username"]! as String,
    password: json["password"]! as String,
    organizations: (json["organizations"]! as List).cast<String>(),
  );

  final String username;

  /// What the password grant accepts: the fixture password for the identity
  /// stand in, the user's app password for Authentik.
  final String password;

  /// The organizations the user belongs to when the stack starts.
  final List<String> organizations;
}

/// The fixture users (`backend/tests/component/fixtures/stack-users.json`).
final List<StackUser> users = [
  for (final user in jsonDecode(_users) as List)
    StackUser.fromJson((user as Map).cast<String, Object?>()),
];

/// The fixture user named [username].
StackUser user(String username) => users.firstWhere(
  (user) => user.username == username,
  orElse: () => throw ArgumentError.value(username, "username", "no fixture"),
);

/// Delays every byte on the panel's NATS link by [latency].
Future<void> natsLatency(Duration latency) => _expect(
  200,
  http.post(
    Uri.parse("$_faults/proxies/$_panelLink/toxics"),
    body: jsonEncode({
      "type": "latency",
      "attributes": {"latency": latency.inMilliseconds},
    }),
  ),
);

/// Cuts or restores the panel's NATS link.
Future<void> natsLink({required bool enabled}) => _expect(
  200,
  http.post(
    Uri.parse("$_faults/proxies/$_panelLink"),
    body: jsonEncode({"enabled": enabled}),
  ),
);

/// Cuts or restores the Realm host's NATS link, so the Realm goes away while
/// the panel stays connected.
Future<void> realmLink({required bool enabled}) => _expect(
  200,
  http.post(
    Uri.parse("$_faults/proxies/realm-nats"),
    body: jsonEncode({"enabled": enabled}),
  ),
);

/// Restores every link and removes every toxic, so the next scenario starts
/// from a healthy stack.
Future<void> resetFaults() =>
    _expect(204, http.post(Uri.parse("$_faults/reset")));

Future<void> _expect(int status, Future<http.Response> request) async {
  final response = await request;
  if (response.statusCode != status) {
    throw StateError(
      "stack control ${response.request?.url} answered "
      "${response.statusCode}: ${response.body}",
    );
  }
}
