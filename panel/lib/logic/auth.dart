import "dart:io";

import "package:flutter/foundation.dart";
import "package:oidc/oidc.dart";
import "package:oidc_default_store/oidc_default_store.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/utils/app_config.dart";

part "auth.g.dart";

class UserInfo {
  const UserInfo({
    required this.sub,
    this.name,
    this.username,
    this.email,
    this.picture,
    this.emailVerified,
  });

  final String sub;
  final String? name;
  final String? username;
  final String? email;
  final String? picture;
  final bool? emailVerified;
}

class AccessToken {
  const AccessToken({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<OidcUserManager?> build() async {
    final config = AppConfig.auth;

    final redirectUri = kIsWeb
        ? Uri.parse(config.redirectUri)
        : Platform.isAndroid || Platform.isIOS || Platform.isMacOS
        ? Uri.parse("com.typewritermc.panel:/oauth2redirect")
        : Platform.isWindows || Platform.isLinux
        ? Uri.parse("http://localhost:0")
        : Uri.parse(config.redirectUri);

    final postLogoutRedirectUri = kIsWeb
        ? Uri.parse(config.postLogoutRedirectUri)
        : Platform.isAndroid || Platform.isIOS || Platform.isMacOS
        ? Uri.parse("com.typewritermc.panel:/endsessionredirect")
        : Platform.isWindows || Platform.isLinux
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
      strictJwtVerification: true,
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

  Future<void> signIn() async {
    debugPrint("Signing in");
    final manager = await future;
    if (manager == null) {
      throw Exception("Auth manager not initialized");
    }
    await manager.loginAuthorizationCodeFlow();
    ref
      ..invalidateSelf()
      ..invalidate(isAuthenticatedProvider)
      ..invalidate(accessTokenProvider)
      ..invalidate(authUserInfoProvider)
      ..invalidate(userIdProvider);
  }

  Future<void> signOut() async {
    debugPrint("Signing out");
    final manager = await future;
    if (manager == null) {
      return;
    }
    await Future.wait([manager.forgetUser(), manager.logout()]);
    ref.invalidateSelf();
  }
}

@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(Ref ref) async {
  final manager = await ref.watch(authProvider.future);
  if (manager == null) {
    return false;
  }
  final user = manager.currentUser;
  return user != null;
}

@Riverpod(keepAlive: true)
Future<String?> userId(Ref ref) async {
  final isAuthenticated = await ref.watch(isAuthenticatedProvider.future);
  if (!isAuthenticated) {
    return null;
  }
  final info = await ref.watch(authUserInfoProvider.future);
  return info.sub;
}

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

  return UserInfo(
    sub: claims.subject ?? "",
    name: claims["name"] as String?,
    username:
        claims["preferred_username"] as String? ?? claims["name"] as String?,
    email: claims["email"] as String?,
    picture: claims["picture"] as String?,
    emailVerified: claims["email_verified"] as bool?,
  );
}
