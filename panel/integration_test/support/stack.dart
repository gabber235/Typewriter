/// The stack a scenario runs against: its fixture users and its fault switches.
///
/// `cargo xtask e2e` passes the stack's `panel.json` through
/// `--dart-define-from-file`, so every value here is a compile time define.
/// The CI cluster's file carries no `STACK_*` control values: failure scenarios
/// check [controllable] and skip there.
///
/// Import with a prefix (`import "support/stack.dart" as stack;`), so calls
/// read as `stack.identityOutage(true)`.
library;

import "dart:convert";

import "package:http/http.dart" as http;

const _identity = String.fromEnvironment("STACK_IDENTITY_URL");
const _faults = String.fromEnvironment("STACK_FAULTS_URL");
const _users = String.fromEnvironment("STACK_USERS", defaultValue: "[]");

/// Whether the stack's faults can be switched, which only a worktree stack
/// allows.
bool get controllable => _identity.isNotEmpty && _faults.isNotEmpty;

/// A fixture user the identity stand in accepts with the password grant.
class StackUser {
  const StackUser({
    required this.username,
    required this.password,
    required this.subject,
    required this.organizations,
  });

  factory StackUser.fromJson(Map<String, Object?> json) => StackUser(
    username: json["username"]! as String,
    password: json["password"]! as String,
    subject: json["subject"]! as String,
    organizations: (json["organizations"]! as List).cast<String>(),
  );

  final String username;
  final String password;

  /// The identity provider subject the backend sees for this user.
  final String subject;

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

/// Makes the identity stand in answer every token request with 503 while
/// [outage] is true.
Future<void> identityOutage(bool outage) => _expect(
  204,
  http.put(
    Uri.parse("$_identity/stack/outage"),
    headers: {"content-type": "application/json"},
    body: jsonEncode(outage),
  ),
);

/// Delays every byte on the panel's NATS link by [latency].
Future<void> natsLatency(Duration latency) => _expect(
  200,
  http.post(
    Uri.parse("$_faults/proxies/nats/toxics"),
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
    Uri.parse("$_faults/proxies/nats"),
    body: jsonEncode({"enabled": enabled}),
  ),
);

/// Restores every link and removes every toxic, so the next scenario starts
/// from a healthy stack.
Future<void> resetFaults() async {
  await _expect(204, http.post(Uri.parse("$_faults/reset")));
  await identityOutage(false);
}

Future<void> _expect(int status, Future<http.Response> request) async {
  if (!controllable) {
    throw StateError("this stack has no fault control; skip the scenario");
  }
  final response = await request;
  if (response.statusCode != status) {
    throw StateError(
      "stack control ${response.request?.url} answered "
      "${response.statusCode}: ${response.body}",
    );
  }
}
