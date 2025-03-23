import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:logto_dart_sdk/logto_client.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "auth.g.dart";

@riverpod
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

@riverpod
Future<bool> isAuthenticated(Ref ref) {
  return ref.watch(authProvider).isAuthenticated;
}

@riverpod
Future<String?> idToken(Ref ref) {
  return ref.watch(authProvider).idToken;
}

@riverpod
Future<LogtoUserInfoResponse> authUserInfo(Ref ref) {
  return ref.watch(authProvider).getUserInfo();
}
