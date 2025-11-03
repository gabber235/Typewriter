import "package:flutter/foundation.dart";
import "package:logto_dart_sdk/logto_client.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/utils/app_config.dart";

part "auth.g.dart";

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  LogtoClient build() {
    final config = LogtoConfig(
      appId: AppConfig.auth.appId,
      endpoint: AppConfig.auth.endpoint,
    );

    return LogtoClient(config: config);
  }

  String _getRedirectUri() {
    if (kIsWeb) {
      return AppConfig.panel.redirectUri;
    }
    return "io.logto://callback";
  }

  Future<void> signIn() async {
    debugPrint("Signing in");
    await state.signIn(_getRedirectUri());
    ref.invalidateSelf();
  }

  Future<void> signOut() async {
    debugPrint("Signing out");
    await state.signOut(_getRedirectUri());
    ref.invalidateSelf();
  }
}

@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(Ref ref) {
  return ref.watch(authProvider).isAuthenticated;
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
Future<AccessToken?> accessToken(Ref ref) {
  return ref
      .watch(authProvider)
      .getAccessToken(resource: AppConfig.panel.resourceUrl);
}

@Riverpod(keepAlive: true)
Future<LogtoUserInfoResponse> authUserInfo(Ref ref) {
  return ref.watch(authProvider).getUserInfo();
}
