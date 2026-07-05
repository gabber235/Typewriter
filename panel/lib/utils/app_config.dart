import "package:flutter/foundation.dart";

class AppConfig {
  AppConfig._();

  static const NatsConfig nats = NatsConfig._();
  static const AuthConfig auth = AuthConfig._();
  static const DocsConfig docs = DocsConfig._();
  static const ApiConfig api = ApiConfig._();
}

class NatsConfig {
  const NatsConfig._();

  String get webUrl => const String.fromEnvironment(
    "NATS_WEB_URL",
    defaultValue: "ws://nats.seamlezz.com:4223",
  );

  String get desktopUrl => const String.fromEnvironment(
    "NATS_DESKTOP_URL",
    defaultValue: "nats://nats.seamlezz.com:4222",
  );

  String get url => kIsWeb ? webUrl : desktopUrl;
}

class AuthConfig {
  const AuthConfig._();

  String get issuer => const String.fromEnvironment(
    "AUTH_ISSUER",
    defaultValue: "https://auth.typewritermc.com/",
  );

  String get clientId => const String.fromEnvironment("AUTH_CLIENT_ID");

  String get scopes => const String.fromEnvironment(
    "AUTH_SCOPES",
    defaultValue: "openid profile email entitlements discord",
  );

  String get redirectUri => const String.fromEnvironment(
    "AUTH_REDIRECT_URI",
    defaultValue: "https://panel.typewritermc.com/redirect.html",
  );

  String get postLogoutRedirectUri => const String.fromEnvironment(
    "AUTH_POST_LOGOUT_REDIRECT_URI",
    defaultValue: "https://panel.typewritermc.com/redirect.html",
  );

  String get frontChannelLogoutUri => const String.fromEnvironment(
    "AUTH_FRONT_CHANNEL_LOGOUT_URI",
    defaultValue:
        "https://panel.typewritermc.com/redirect.html?requestType=front-channel-logout",
  );

  String get discoveryDocumentUri => const String.fromEnvironment(
    "AUTH_DISCOVERY_DOCUMENT_URI",
    defaultValue:
        "https://auth.typewritermc.com/application/o/typewriter-panel/.well-known/openid-configuration",
  );
}

class DocsConfig {
  const DocsConfig._();

  String get baseUrl => const String.fromEnvironment(
    "DOCS_BASE_URL",
    defaultValue: "https://docs.typewritermc.com",
  );

  String get engineDocsUrl => "$baseUrl/develop";

  String get extensionsDocsUrl => "$baseUrl/develop/extensions";
}

class ApiConfig {
  const ApiConfig._();

  String get baseUrl => const String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://api.typewritermc.com",
  );
}
