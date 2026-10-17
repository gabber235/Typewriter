import "package:typewriter_panel/typewriter_panel.dart";

/// Build time configuration grouped by the boundary that consumes it.
///
/// Values come from `String.fromEnvironment` and are therefore fixed when the
/// Flutter application is compiled. Runtime code should read the relevant
/// grouped configuration instead of duplicating environment variable names.
class AppConfig {
  AppConfig._();

  static const NatsConfig nats = NatsConfig._();
  static const AuthConfig auth = AuthConfig._();
  static const DocsConfig docs = DocsConfig._();
  static const ApiConfig api = ApiConfig._();
  static const TelemetryConfig telemetry = TelemetryConfig._();
}

/// OpenTelemetry exporter settings supplied to the panel at build time.
class TelemetryConfig {
  const TelemetryConfig._();

  bool get enabled =>
      const bool.fromEnvironment("OTEL_ENABLED", defaultValue: false);

  String get tracesEndpoint => const String.fromEnvironment(
    "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT",
    defaultValue: "",
  );
}

/// NATS endpoints for browser and non browser panel builds.
///
/// [url] selects the browser WebSocket endpoint on web and the native NATS
/// endpoint everywhere else. The individual getters remain available for
/// callers that need to construct a platform specific connection explicitly.
class NatsConfig {
  const NatsConfig._();

  String get webUrl => const String.fromEnvironment(
    "NATS_WEB_URL",
    defaultValue: "wss://nats.seamlezz.com",
  );

  String get desktopUrl => const String.fromEnvironment(
    "NATS_DESKTOP_URL",
    defaultValue: "nats://nats.seamlezz.com:4222",
  );

  String get url => kIsWeb ? webUrl : desktopUrl;
}

/// OpenID Connect settings used by the panel authentication boundary.
///
/// These values are compile time configuration. [scopes] is a space separated
/// scope string as required by the authorization client.
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
    defaultValue: "https://panel.typewritermc.com/redirect.html?requestType=front-channel-logout",
  );

  String get discoveryDocumentUri => const String.fromEnvironment(
    "AUTH_DISCOVERY_DOCUMENT_URI",
    defaultValue: "https://auth.typewritermc.com/application/o/typewriter-panel/.well-known/openid-configuration",
  );
}

/// URLs for documentation links presented by the panel.
class DocsConfig {
  const DocsConfig._();

  String get baseUrl => const String.fromEnvironment(
    "DOCS_BASE_URL",
    defaultValue: "https://docs.typewritermc.com",
  );

  String get engineDocsUrl => "$baseUrl/develop";

  String get extensionsDocsUrl => "$baseUrl/develop/extensions";
}

/// Base URL for the panel's HTTP API integrations.
class ApiConfig {
  const ApiConfig._();

  String get baseUrl => const String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "https://api.typewritermc.com",
  );
}
