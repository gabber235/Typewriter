import "package:typewriter_panel/typewriter_panel.dart";

part "auth.freezed.dart";
part "auth.g.dart";

bool _usesCustomSchemeRedirect() {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    _ => false,
  };
}

bool _usesLoopbackRedirect() {
  if (kIsWeb) {
    return false;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.linux => true,
    _ => false,
  };
}

/// Identity claims exposed to the panel after the identity provider validates a session.
///
/// This is the panel's normalized read model for account display and authenticated
/// transport setup. The claims remain optional because providers may omit profile
/// fields; [sub] is the stable identity used by user scoped backend subjects.
@freezed
abstract class UserInfo with _$UserInfo {
  const factory UserInfo({
    required String sub,
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    bool? emailVerified,
    List<String>? entitlements,
    List<String>? groups,
    DiscordInfo? discord,
  }) = _UserInfo;
}

/// Optional Discord profile claims attached to [UserInfo].
///
/// Discord data is descriptive only. Authorization still comes from the identity
/// provider session and backend responses.
@freezed
abstract class DiscordInfo with _$DiscordInfo {
  const factory DiscordInfo({
    required String id,
    String? username,
    String? avatarUrl,
    String? email,
    List<String>? roles,
  }) = _DiscordInfo;
}

/// The bearer token and its provider supplied expiry, when known.
///
/// Transport adapters consume this value at the authentication boundary. The
/// identity provider manager, owned by [Auth], refreshes credentials before they
/// expire; a missing expiry means the provider supplied no lifetime.
@freezed
abstract class AccessToken with _$AccessToken {
  const factory AccessToken({required String token, DateTime? expiresAt}) =
      _AccessToken;
}

/// Where the OIDC client persists tokens and flow state.
///
/// Production uses the platform store. End to end scenarios replace it with an
/// in memory store, so they need no keychain or keyring.
@Riverpod(keepAlive: true)
OidcStore oidcStore(Ref ref) => OidcDefaultStore();

/// Ends the identity provider's session for a signed in [OidcUserManager].
///
/// Production runs the provider's end session flow, which opens the browser
/// on native platforms. End to end scenarios replace it, so a run never leaves
/// browser tabs behind; the local sign out they check runs either way.
@Riverpod(keepAlive: true)
Future<void> Function(OidcUserManager manager) providerSessionEnd(Ref ref) =>
    (manager) => manager.logout();

/// Owns the panel's identity provider session for the application lifetime.
///
/// Construction selects the redirect flow required by the current platform,
/// initializes the OIDC manager, and restores any persisted session. Web sign in
/// navigates in the current tab and restores the session on return. Native sign
/// in and sign out invalidate this provider so consumers observe the new session
/// through Riverpod rather than retaining their own authentication state.
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<OidcUserManager?> build() async {
    final config = AppConfig.auth;

    final redirectUri = kIsWeb
        ? Uri.parse(config.redirectUri)
        : _usesCustomSchemeRedirect()
        ? Uri.parse("com.typewritermc.panel:/oauth2redirect")
        : _usesLoopbackRedirect()
        ? Uri.parse("http://localhost:0")
        : Uri.parse(config.redirectUri);

    final postLogoutRedirectUri = kIsWeb
        ? Uri.parse(config.postLogoutRedirectUri)
        : _usesCustomSchemeRedirect()
        ? Uri.parse("com.typewritermc.panel:/endsessionredirect")
        : _usesLoopbackRedirect()
        ? Uri.parse("http://localhost:0")
        : null;

    final frontChannelLogoutUri = kIsWeb
        ? Uri.parse(config.frontChannelLogoutUri)
        : null;

    final settings = OidcUserManagerSettings(
      redirectUri: redirectUri,
      postLogoutRedirectUri: postLogoutRedirectUri,
      frontChannelLogoutUri: frontChannelLogoutUri,
      scope: config.scopes.split(" "),
      initMode: OidcInitMode.blockingValidate,
      supportOfflineAuth: false,
      refreshBefore: (token) => const Duration(seconds: 30),
    );

    final discoveryDocumentUri = config.discoveryDocumentUri.isNotEmpty
        ? Uri.parse(config.discoveryDocumentUri)
        : OidcUtils.getOpenIdConfigWellKnownUri(Uri.parse(config.issuer));

    final manager = OidcUserManager.lazy(
      discoveryDocumentUri: discoveryDocumentUri,
      clientCredentials: OidcClientAuthentication.none(
        clientId: config.clientId,
      ),
      store: ref.watch(oidcStoreProvider),
      settings: settings,
    );

    await manager.init();

    return manager;
  }

  /// Starts authorization in the configured identity provider and refreshes
  /// dependent session consumers after the callback completes.
  ///
  /// Web authorization uses the current tab. The redirect page restores the
  /// original panel URL, and initialization completes the stored response.
  Future<void> signIn() async {
    debugPrint("Signing in");
    final manager = await future;
    if (manager == null) {
      throw Exception("Auth manager not initialized");
    }
    await manager.loginAuthorizationCodeFlow(
      originalUri: kIsWeb ? Uri.base : null,
      options: kIsWeb
          ? const OidcPlatformSpecificOptions(
              web: OidcPlatformSpecificOptions_Web(
                navigationMode:
                    OidcPlatformSpecificOptions_Web_NavigationMode.samePage,
              ),
            )
          : null,
    );
    if (!kIsWeb) {
      ref.invalidateSelf();
    }
  }

  /// Forgets the session locally, then ends the provider session in the
  /// background.
  ///
  /// The panel is signed out once the stored session and tokens are gone, so
  /// it never waits on the provider's end session flow (a browser sheet on
  /// native platforms, another tab on the web). Failing to end the provider
  /// session is reported and leaves the user signed out locally. A missing
  /// manager is treated as an already ended session. Provider invalidation
  /// makes the signed out state observable to routes and transport clients.
  Future<void> signOut() async {
    debugPrint("Signing out");
    final manager = await future;
    if (manager == null) {
      return;
    }
    // The end session request reads the current session when it starts, so it
    // starts before the session is forgotten.
    final endProviderSession = ref.read(providerSessionEndProvider);
    unawaited(
      runPanelMutation(
        operation: PanelMutationOperation.endProviderSession,
        mutation: () => endProviderSession(manager),
        recover: (_, _) {},
      ),
    );
    await runPanelMutation(
      operation: PanelMutationOperation.signOut,
      mutation: manager.forgetUser,
    );
    ref.invalidateSelf();
  }
}

/// The signed in user and the token they act with, read from the identity
/// provider in one step.
///
/// Every session consumer derives from this one value, so a consumer that saw
/// the user also sees the token: the identity and the transport credentials
/// can never disagree about whether sign in has completed.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required AccessToken token,
    required UserInfo user,
  }) = _AuthSession;
}

/// The current identity provider session, or null when nobody is signed in.
///
/// Initialization failure remains an async provider failure. A missing manager,
/// user or access token produces null. Expiry is derived from the provider
/// token timestamps and is absent when the provider supplies no lifetime.
@Riverpod(keepAlive: true)
Future<AuthSession?> authSession(Ref ref) async {
  final manager = await ref.watch(authProvider.future);
  final user = manager?.currentUser;
  final token = user?.token.accessToken;
  if (user == null || token == null) {
    return null;
  }
  final expiresIn = user.token.expiresIn;
  return AuthSession(
    token: AccessToken(
      token: token,
      expiresAt: expiresIn == null
          ? null
          : user.token.creationTime.add(expiresIn),
    ),
    user: _userInfo(user),
  );
}

/// Reports whether the identity provider has a current session.
///
/// Initialization failure remains an async provider failure. Without a session
/// this is false so route guards can keep unauthenticated users on sign in.
@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(Ref ref) async =>
    await ref.watch(authSessionProvider.future) != null;

/// Returns the authenticated provider subject used for user scoped backend calls.
///
/// Returns null when no session exists. This keeps unauthenticated consumers from
/// constructing subjects with an invented identity.
@Riverpod(keepAlive: true)
Future<String?> userId(Ref ref) async =>
    (await ref.watch(authSessionProvider.future))?.user.sub;

/// Watching what only a signed in user can see.
extension SignedInWatch on Ref {
  /// The stream [open] starts for the signed in user, or [signedOut] alone
  /// while nobody is signed in.
  ///
  /// The user is watched now, while the provider builds, so a new user
  /// rebuilds it. [open] runs once the user is known and only while the
  /// provider still listens to the result, so it may watch further
  /// providers: a provider disposed first never runs [open] and never
  /// touches its ref again.
  Stream<T> watchSignedIn<T>(
    Stream<T> Function(String userId) open, {
    required T signedOut,
  }) => Stream.fromFuture(watch(userIdProvider.future)).asyncExpand(
    (userId) => userId == null ? Stream.value(signedOut) : open(userId),
  );
}

/// Normalizes the provider claims of [user] into the panel's account model.
UserInfo _userInfo(OidcUser user) {
  final claims = user.claims;
  DiscordInfo? discordInfo;
  final discordClaims = claims["discord"];
  if (discordClaims is Map<String, dynamic>) {
    discordInfo = DiscordInfo(
      id: discordClaims["id"] as String? ?? "",
      username: discordClaims["username"] as String?,
      avatarUrl: discordClaims["avatar_url"] as String?,
      email: discordClaims["email"] as String?,
      roles: discordClaims["roles"] is List
          ? List<String>.from(discordClaims["roles"] as List)
          : null,
    );
  }

  final avatarUrl =
      claims["avatar_url"] as String? ??
      discordInfo?.avatarUrl ??
      claims["picture"] as String?;

  return UserInfo(
    sub: claims.subject ?? "",
    name: claims["name"] as String? ?? claims["given_name"] as String?,
    username:
        claims["preferred_username"] as String? ??
        claims["nickname"] as String? ??
        claims["name"] as String?,
    email: claims["email"] as String?,
    avatarUrl: avatarUrl,
    emailVerified: claims["email_verified"] as bool?,
    entitlements: claims["entitlements"] is List
        ? List<String>.from(claims["entitlements"] as List)
        : null,
    groups: claims["groups"] is List
        ? List<String>.from(claims["groups"] as List)
        : null,
    discord: discordInfo,
  );
}

/// The generated avatar shown for a user without a provider avatar.
const userIconUrl =
    "https://api.dicebear.com/9.x/bottts-neutral/webp?backgroundColor=00897b,00acc1,039be5,1e88e5,3949ab,43a047,5e35b1,7cb342,8e24aa,b6e3f4,c0aede,c0ca33,d1d4f9,d81b60,e53935,f4511e,fb8c00,fdd835,ffb300,ffd5dc,ffdfbf&eyes=eva,frame1,frame2,robocop,roundFrame01,roundFrame02,sensor,shade01&mouth=bite,diagram,smile01,smile02&backgroundType=gradientLinear";
