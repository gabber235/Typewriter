import "package:typewriter_panel/typewriter_panel.dart";

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
class UserInfo {
  const UserInfo({
    required this.sub,
    this.name,
    this.username,
    this.email,
    this.avatarUrl,
    this.emailVerified,
    this.entitlements,
    this.groups,
    this.discord,
  });

  final String sub;
  final String? name;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final bool? emailVerified;
  final List<String>? entitlements;
  final List<String>? groups;
  final DiscordInfo? discord;
}

/// Optional Discord profile claims attached to [UserInfo].
///
/// Discord data is descriptive only. Authorization still comes from the identity
/// provider session and backend responses.
class DiscordInfo {
  const DiscordInfo({
    required this.id,
    this.username,
    this.avatarUrl,
    this.email,
    this.roles,
  });

  final String id;
  final String? username;
  final String? avatarUrl;
  final String? email;
  final List<String>? roles;
}

/// The bearer token and its provider supplied expiry, when known.
///
/// Transport adapters consume this value at the authentication boundary. The
/// identity provider manager, owned by [Auth], refreshes credentials before they
/// expire; a missing expiry means the provider supplied no lifetime.
class AccessToken {
  const AccessToken({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;
}

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
      store: OidcDefaultStore(),
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

  /// Ends the provider session and removes its locally stored credentials.
  ///
  /// A missing manager is treated as an already ended session. Mutation
  /// instrumentation owns the visible operation status; provider invalidation
  /// makes the signed out state observable to routes and transport clients.
  Future<void> signOut() async {
    debugPrint("Signing out");
    final manager = await future;
    if (manager == null) {
      return;
    }
    await runPanelMutation(
      operation: PanelMutationOperation.signOut,
      mutation: () => Future.wait([manager.forgetUser(), manager.logout()]),
    );
    ref.invalidateSelf();
  }
}

/// Reports whether the initialized identity provider has a current user.
///
/// Initialization failure remains an async provider failure. A missing manager or
/// user produces false so route guards can keep unauthenticated users on sign in.
@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(Ref ref) async {
  final manager = await ref.watch(authProvider.future);
  if (manager == null) {
    return false;
  }
  final user = manager.currentUser;
  return user != null;
}

/// Returns the authenticated provider subject used for user scoped backend calls.
///
/// Returns null when no session exists. This keeps unauthenticated consumers from
/// constructing subjects with an invented identity.
@Riverpod(keepAlive: true)
Future<String?> userId(Ref ref) async {
  final isAuthenticated = await ref.watch(isAuthenticatedProvider.future);
  if (!isAuthenticated) {
    return null;
  }
  final info = await ref.watch(authUserInfoProvider.future);
  return info.sub;
}

/// Projects the current provider token for transport adapters.
///
/// Returns null when the manager, user, or access token is unavailable. Expiry is
/// derived from the provider token timestamps and is absent when the provider
/// does not supply a lifetime.
@Riverpod(keepAlive: true)
Future<AccessToken?> accessToken(Ref ref) async {
  final manager = await ref.watch(authProvider.future);
  if (manager == null) {
    return null;
  }
  final user = manager.currentUser;
  if (user == null) {
    return null;
  }
  final token = user.token.accessToken;
  if (token == null) {
    return null;
  }

  final expiresAt = user.token.expiresIn != null
      ? user.token.creationTime.add(user.token.expiresIn!)
      : null;
  return AccessToken(token: token, expiresAt: expiresAt);
}

/// Normalizes provider claims into the account model consumed by the panel.
///
/// This provider is intentionally strict about session presence. Callers that can
/// render signed out state should use [isAuthenticatedProvider] first; callers
/// that need identity setup should surface its failure instead of guessing claims.
@Riverpod(keepAlive: true)
Future<UserInfo> authUserInfo(Ref ref) async {
  final manager = await ref.watch(authProvider.future);
  if (manager == null) {
    throw Exception("Auth manager not initialized");
  }
  final user = manager.currentUser;
  if (user == null) {
    throw Exception("User not authenticated");
  }
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
