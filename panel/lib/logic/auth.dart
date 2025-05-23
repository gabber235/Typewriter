import "package:flutter/foundation.dart";
import "package:logto_dart_sdk/logto_client.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "auth.g.dart";

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  LogtoClient build() {
    final config = LogtoConfig(
      appId: "xqytbpo52htzlkhoh0wt3",
      endpoint: "https://auth.typewritermc.com/",
    );

    return LogtoClient(config: config);
  }

  String _getRedirectUri() {
    if (kIsWeb) {
      if (kDebugMode) {
        return "http://localhost:2350/callback.html";
      }
      return "https://panel.typewritermc.com/callback.html";
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
      .getAccessToken(resource: "https://panel.typewritermc.com");
}

@Riverpod(keepAlive: true)
Future<LogtoUserInfoResponse> authUserInfo(Ref ref) {
  return ref.watch(authProvider).getUserInfo();
}
