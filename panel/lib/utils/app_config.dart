import "package:flutter/foundation.dart";

class AppConfig {
  AppConfig._();

  static const NatsConfig nats = NatsConfig._();
  static const AuthConfig auth = AuthConfig._();
  static const DocsConfig docs = DocsConfig._();
}

class NatsConfig {
  const NatsConfig._();

  String get webUrl => const String.fromEnvironment(
    "NATS_WEB_URL",
    defaultValue: "ws://localhost:4223",
  );

  String get desktopUrl => const String.fromEnvironment(
    "NATS_DESKTOP_URL",
    defaultValue: "nats://localhost:4222",
  );

  String get sentinelJwt => const String.fromEnvironment(
    "NATS_SENTINEL_JWT",
    defaultValue:
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJlZDI1NTE5LW5rZXkifQ.eyJqdGkiOiJUWVFNSVhCUUJNSEhOUzdWTU1RRk1OSlhBVENWS1RJRUJGTlVEQzRWNVpQUTY2NVgzMkRBIiwiaWF0IjoxNzQ1NzI4NjQ4LCJpc3MiOiJBQlU2SFRaTEpETUU3TFBHU0xBVkdNSjJXS0Y1TUlOQzZKTlRIR0JLMlFKRzJRNjVKUkU0VEFOUSIsIm5hbWUiOiJzZW50aW5lbCIsInN1YiI6IlVDRkpZSVozVkdNSzVJSElJUldPNlJIRU9ISVhJVE1QNEhZNERHSEJTMk8yRkU0SUI2TlM2RjNLIiwibmF0cyI6eyJwdWIiOnsiZGVueSI6WyJcdTAwM2UiXX0sInN1YiI6eyJkZW55IjpbIlx1MDAzZSJdfSwic3VicyI6LTEsImRhdGEiOi0xLCJwYXlsb2FkIjotMSwiaXNzdWVyX2FjY291bnQiOiJBQ05BWVZJQVZNQ0FVU0c1NUg2WUhXT0dRVlUzQUhNRVoyNFBYNVVPMkEyNkYzTUZBSVFSM0dGSyIsInR5cGUiOiJ1c2VyIiwidmVyc2lvbiI6Mn19.QYjsUBqshe5G7FNuDGg1ouxevrJ3sHAqJj0G8VCeVUhJLH3tl2v6nuS8UtICuz5g-BlId2Tg_wAjumQW5tHFAA",
  );

  String get sentinelSeed => const String.fromEnvironment(
    "NATS_SENTINEL_SEED",
    defaultValue: "SUAG6J2O4ULGEZBKLVFQIDHFIZWR5PVEAROIQTE5VISCE3VCMFI2AHS25U",
  );

  bool get acceptBadCert =>
      const bool.fromEnvironment("NATS_ACCEPT_BAD_CERT", defaultValue: false);

  String get url => kIsWeb ? webUrl : desktopUrl;
}

class AuthConfig {
  const AuthConfig._();

  String get issuer => const String.fromEnvironment(
    "AUTH_ISSUER",
    defaultValue: "https://auth.typewritermc.com/",
  );

  String get clientId => const String.fromEnvironment(
    "AUTH_CLIENT_ID",
    defaultValue: "xqytbpo52htzlkhoh0wt3",
  );

  String get scopes => const String.fromEnvironment(
    "AUTH_SCOPES",
    defaultValue: "openid profile email",
  );

  String get redirectUri => const String.fromEnvironment(
    "AUTH_REDIRECT_URI",
    defaultValue: "http://localhost:2350/redirect.html",
  );

  String get postLogoutRedirectUri => const String.fromEnvironment(
    "AUTH_POST_LOGOUT_REDIRECT_URI",
    defaultValue: "http://localhost:2350/redirect.html",
  );

  String get frontChannelLogoutUri => const String.fromEnvironment(
    "AUTH_FRONT_CHANNEL_LOGOUT_URI",
    defaultValue: "http://localhost:2350/redirect.html",
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
