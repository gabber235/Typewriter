import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A person who signs in to the panel in a test world.
final class PanelUser {
  const PanelUser({required this.id, required this.name, this.email});

  /// The identity provider subject; backend subjects are scoped by it.
  final String id;
  final String name;
  final String? email;

  @override
  String toString() => name;
}

/// The identity provider session of a test world.
///
/// Replaces the identity provider client, the one source the panel derives
/// signed in state, user identity and access tokens from. Signing out ends the
/// session the way the real client does, so routes and transports react to it.
final class FakeSession {
  FakeSession({this._user});

  PanelUser? _user;

  /// The signed in user, or null when nobody is signed in.
  PanelUser? get user => _user;

  /// The credentials the panel fetches before it connects to NATS.
  final sentinel = skir.GetSentinelCredentialsResponse_Success(
    jwt: "test-jwt",
    seed: "test-seed",
  );

  /// Replaces the identity provider and its credential endpoint.
  List<Override> get overrides => [
    authProvider.overrideWith(() => _FakeAuth(this)),
    oidcStoreProvider.overrideWithValue(OidcMemoryStore()),
    sentinelCredentialsProvider.overrideWith((ref) async => sentinel),
  ];

  Future<OidcUserManager?> _manager() async {
    final user = _user;
    if (user == null) return _SignedOutManager(this);
    return _SignedInManager(this, await _oidcUser(user));
  }
}

final class _FakeAuth extends Auth {
  _FakeAuth(this._session);

  final FakeSession _session;

  @override
  Future<OidcUserManager?> build() => _session._manager();

  @override
  Future<void> signIn() async {
    throw StateError(
      "Signing in runs through the identity provider; start the world "
      "with signedIn(user) instead",
    );
  }
}

Future<OidcUser> _oidcUser(PanelUser user) {
  final now = clock.now();
  String encode(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll("=", "");
  final claims = {
    "iss": "https://identity.test",
    "aud": "panel",
    "sub": user.id,
    "name": user.name,
    "preferred_username": user.name,
    "email": ?user.email,
    "iat": now.millisecondsSinceEpoch ~/ 1000,
    "exp": now.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000,
  };
  final idToken = "${encode({"alg": "none"})}.${encode(claims)}.";
  return OidcUser.fromIdToken(
    token: OidcToken(
      creationTime: now,
      accessToken: "access-token-${user.id}",
      idToken: idToken,
      expiresIn: const Duration(days: 1),
    ),
  );
}

OidcUserManagerSettings get _settings =>
    OidcUserManagerSettings(redirectUri: Uri.parse("https://panel.test"));

/// A client whose session never reached the identity provider.
final class _SignedOutManager extends OidcUserManager {
  _SignedOutManager(this.session)
    : super.lazy(
        discoveryDocumentUri: Uri.parse("https://identity.test"),
        clientCredentials: const OidcClientAuthentication.none(
          clientId: "panel",
        ),
        store: OidcMemoryStore(),
        settings: _settings,
      );

  final FakeSession session;

  @override
  OidcUser? get currentUser => null;

  @override
  Future<void> forgetUser() async {}

  @override
  Future<void> logout({
    String? logoutHint,
    Map<String, dynamic>? extraParameters,
    OidcPlatformSpecificOptions? options,
    Uri? postLogoutRedirectUriOverride,
    Uri? originalUri,
    dynamic extraStateData,
    List<String>? uiLocalesOverride,
    OidcProviderMetadata? discoveryDocumentOverride,
  }) async {}
}

/// A client holding one valid session until the user signs out.
final class _SignedInManager extends _SignedOutManager {
  _SignedInManager(super.session, this._user);

  final OidcUser _user;

  @override
  OidcUser? get currentUser => session._user == null ? null : _user;

  @override
  Future<void> forgetUser() async => session._user = null;
}
