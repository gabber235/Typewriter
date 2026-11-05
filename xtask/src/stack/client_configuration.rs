//! How clients reach a backend, in the two formats they read: `panel.json` for
//! `--dart-define-from-file` and `realm.properties` for `TYPEWRITER_CONFIG_FILE`. A worktree stack
//! and the CI cluster write the same keys, so scenarios read the same values and switch the same
//! faults on both targets.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result};
use serde_json::Value;

use super::spec::StackContext;
use crate::Context;
use crate::cluster::CiClients;

/// The OAuth application the panel signs in with.
pub const PANEL_CLIENT_ID: &str = "typewriter-panel";
/// The OAuth application services and hosts sign in with.
pub const SERVICES_CLIENT_ID: &str = "typewriter-services";
/// The fixture users every stack knows, shared with the panel tests.
pub const FIXTURE_USERS: &str = "backend/tests/component/fixtures/stack-users.json";
/// The panel's configuration for the local development cluster.
const LOCAL_PANEL_CONFIG: &str = "panel/config/local.json";

pub struct ClientConfiguration {
    /// Each NATS address goes through its own faults link, so scenarios can cut the desktop
    /// panel's, the web panel's or the Realm host's connection alone.
    pub nats_desktop_url: String,
    pub nats_web_url: String,
    pub nats_host_url: String,
    pub api_base_url: String,
    pub auth_base_url: String,
    pub auth_issuer: String,
    pub auth_discovery_document_uri: String,
    /// The panel's sign in page settings, by `AppConfig` key; empty for the identity stand in,
    /// which has no pages.
    pub sign_in_pages: BTreeMap<&'static str, String>,
    pub control: StackControl,
    /// Where clients export spans; present only on a worktree stack. The CI cluster keeps its
    /// own telemetry settings, so its clients trace nothing here.
    pub telemetry: Option<TelemetryEndpoints>,
}

/// The worktree stack's collector, as each client reaches it.
pub struct TelemetryEndpoints {
    /// The OTLP over HTTP traces route the panel exports to.
    pub panel_traces: String,
    /// The OTLP over gRPC endpoint; the loader exports over gRPC only.
    pub otlp_grpc: String,
}

/// What scenarios switch and who they sign in as.
pub struct StackControl {
    /// Toxiproxy's API as a browser may call it: the links `nats`, `nats-web` and `realm-nats`.
    pub faults_url: String,
    /// The users scenarios sign in as, in the fixture's format, with the password the password
    /// grant accepts.
    pub users_file: PathBuf,
}

impl ClientConfiguration {
    /// The worktree stack's addresses.
    pub fn worktree(ctx: &StackContext) -> Self {
        let identity = ctx.url("http", "identity");
        Self {
            nats_desktop_url: ctx.url("nats", "nats-proxy"),
            nats_web_url: ctx.url("ws", "nats-web-proxy"),
            nats_host_url: ctx.url("nats", "realm-nats-proxy"),
            api_base_url: ctx.url("http", "http"),
            auth_base_url: identity.clone(),
            auth_issuer: format!("{identity}/application/o/{PANEL_CLIENT_ID}/"),
            auth_discovery_document_uri: format!(
                "{identity}/application/o/{PANEL_CLIENT_ID}/.well-known/openid-configuration"
            ),
            sign_in_pages: BTreeMap::new(),
            control: StackControl {
                faults_url: ctx.url("http", "faults"),
                users_file: ctx.root().join(FIXTURE_USERS),
            },
            telemetry: Some(TelemetryEndpoints {
                panel_traces: format!("{}/v1/traces", ctx.url("http", "collector-http")),
                otlp_grpc: ctx.url("http", "collector-grpc"),
            }),
        }
    }

    /// The CI cluster's addresses, with its test users in `users_file`. Its overlay is the local
    /// overlay with decryption, images and resources swapped and faults links added, so it
    /// answers on the addresses and scopes the panel's local configuration names, each NATS
    /// address through the faults link `ci` names. Its Authentik sends the panel back to the
    /// origin `ci` names, so the sign in pages are the panel's own routes from its configuration
    /// at that origin instead of local.json's.
    pub fn ci_cluster(ctx: &Context, ci: &CiClients, users_file: PathBuf) -> Result<Self> {
        let file = ctx.root.join(LOCAL_PANEL_CONFIG);
        let config: Value = serde_json::from_str(
            &fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}", file.display()))?,
        )
        .with_context(|| format!("{} is not JSON", file.display()))?;
        let key = |name: &str| {
            config[name]
                .as_str()
                .map(str::to_owned)
                .with_context(|| format!("{} has no {name}", file.display()))
        };
        let issuer = key("AUTH_ISSUER")?;
        let nats = key("NATS_DESKTOP_URL")?;
        let page = |name: &str| -> Result<String> {
            Ok(with_origin(&key(name)?, &ci.panel_origin.origin))
        };
        Ok(Self {
            nats_desktop_url: with_port(&nats, ci.links.nats),
            nats_web_url: with_port(&key("NATS_WEB_URL")?, ci.links.nats_web),
            nats_host_url: with_port(&nats, ci.links.realm_nats),
            api_base_url: key("API_BASE_URL")?,
            auth_base_url: issuer.trim_end_matches('/').to_owned(),
            auth_issuer: issuer,
            auth_discovery_document_uri: key("AUTH_DISCOVERY_DOCUMENT_URI")?,
            sign_in_pages: BTreeMap::from([
                ("AUTH_SCOPES", key("AUTH_SCOPES")?),
                ("AUTH_REDIRECT_URI", page("AUTH_REDIRECT_URI")?),
                (
                    "AUTH_POST_LOGOUT_REDIRECT_URI",
                    page("AUTH_POST_LOGOUT_REDIRECT_URI")?,
                ),
                (
                    "AUTH_FRONT_CHANNEL_LOGOUT_URI",
                    page("AUTH_FRONT_CHANNEL_LOGOUT_URI")?,
                ),
            ]),
            control: StackControl {
                faults_url: ci.faults_url.clone(),
                users_file,
            },
            telemetry: None,
        })
    }

    /// The values the command under test reads from `stack.env`, naming the client files in
    /// `state`. Later services read the clients typed, through `StackContext::clients`.
    pub fn published(&self, state: &Path) -> [(String, String); 9] {
        [
            ("STACK_API_BASE_URL", self.api_base_url.clone()),
            ("STACK_AUTH_BASE_URL", self.auth_base_url.clone()),
            ("STACK_AUTH_ISSUER", self.auth_issuer.clone()),
            ("STACK_NATS_URL", self.nats_host_url.clone()),
            ("STACK_NATS_DESKTOP_URL", self.nats_desktop_url.clone()),
            ("STACK_NATS_WEB_URL", self.nats_web_url.clone()),
            (
                "STACK_USERS_FILE",
                self.control.users_file.display().to_string(),
            ),
            (
                "STACK_PANEL_DEFINES",
                state.join("panel.json").display().to_string(),
            ),
            (
                "TYPEWRITER_CONFIG_FILE",
                state.join("realm.properties").display().to_string(),
            ),
        ]
        .map(|(key, value)| (key.to_owned(), value))
    }

    pub fn write(&self, dir: &Path) -> Result<()> {
        let panel = dir.join("panel.json");
        fs::write(
            &panel,
            serde_json::to_string_pretty(&self.panel_defines()?)?,
        )
        .with_context(|| format!("cannot write {}", panel.display()))?;
        let realm = dir.join("realm.properties");
        fs::write(&realm, self.realm_properties())
            .with_context(|| format!("cannot write {}", realm.display()))
    }

    /// Keys `AppConfig` reads (`panel/lib/shared/utilities/app_config.dart`), plus `STACK_*` for
    /// the test harness.
    fn panel_defines(&self) -> Result<BTreeMap<&'static str, String>> {
        let users_file = &self.control.users_file;
        let users: Value = serde_json::from_str(
            &fs::read_to_string(users_file)
                .with_context(|| format!("cannot read {}", users_file.display()))?,
        )
        .with_context(|| format!("{} is not JSON", users_file.display()))?;
        let mut defines = BTreeMap::from([
            ("NATS_DESKTOP_URL", self.nats_desktop_url.clone()),
            ("NATS_WEB_URL", self.nats_web_url.clone()),
            ("API_BASE_URL", self.api_base_url.clone()),
            ("AUTH_ISSUER", self.auth_issuer.clone()),
            (
                "AUTH_DISCOVERY_DOCUMENT_URI",
                self.auth_discovery_document_uri.clone(),
            ),
            ("AUTH_CLIENT_ID", PANEL_CLIENT_ID.into()),
            ("OTEL_ENABLED", self.telemetry.is_some().to_string()),
            ("STACK_FAULTS_URL", self.control.faults_url.clone()),
            ("STACK_USERS", users.to_string()),
        ]);
        defines.extend(self.sign_in_pages.clone());
        if let Some(telemetry) = &self.telemetry {
            defines.insert(
                "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT",
                telemetry.panel_traces.clone(),
            );
        }
        Ok(defines)
    }

    /// The loader's settings (`services/runtime/loader/core/.../LoaderSettings.kt`), with the
    /// embedded Realm database `services/runtime/config/local.properties` uses.
    fn realm_properties(&self) -> String {
        let mut settings = vec![
            ("API_BASE_URL", self.api_base_url.as_str()),
            ("AUTH_BASE_URL", self.auth_base_url.as_str()),
            ("JWT_CLIENT_ID", SERVICES_CLIENT_ID),
            ("JWT_SCOPES", "openid profile entitlements"),
            ("NATS_URL", self.nats_host_url.as_str()),
            ("REALM_DB_ENDPOINT_TYPE", "embedded"),
            ("REALM_DB_ENGINE", "surrealkv"),
            ("REALM_DB_PATH", "database/realm"),
            ("REALM_DB_NAMESPACE", "typewriter"),
            ("REALM_DB_DATABASE", "realm"),
            ("REALM_DB_AUTHENTICATION", "none"),
        ];
        match &self.telemetry {
            Some(telemetry) => settings.extend([
                ("OTEL_TRACES_SAMPLER", "always_on"),
                ("OTEL_EXPORTER_OTLP_ENDPOINT", telemetry.otlp_grpc.as_str()),
            ]),
            None => settings.push(("OTEL_TRACES_SAMPLER", "always_off")),
        }
        settings
            .iter()
            .map(|(key, value)| format!("{key}={}\n", value.replace(':', "\\:")))
            .collect()
    }
}

/// `url` with its port replaced by, or set to, `port`, such as `wss://nats.example.com` with
/// 18000 as `wss://nats.example.com:18000`.
fn with_port(url: &str, port: u16) -> String {
    let (scheme, rest) = url.split_once("://").unwrap_or(("", url));
    let (authority, path) = rest.split_at(rest.find('/').unwrap_or(rest.len()));
    let host = authority.split(':').next().unwrap_or(authority);
    let prefix = if scheme.is_empty() {
        String::new()
    } else {
        format!("{scheme}://")
    };
    format!("{prefix}{host}:{port}{path}")
}

/// `uri`'s path and query at `origin` instead of its own, such as
/// `http://localhost:2350/redirect.html` at `http://localhost:4000` as
/// `http://localhost:4000/redirect.html`.
fn with_origin(uri: &str, origin: &str) -> String {
    let rest = uri.split_once("://").map_or(uri, |(_, rest)| rest);
    let path = rest.find(['/', '?', '#']).map_or("", |at| &rest[at..]);
    format!("{}{path}", origin.trim_end_matches('/'))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{TempRoot, ci_clients};

    #[test]
    fn the_ci_panel_signs_in_and_out_on_its_own_routes_at_the_origin_clients_json_names() {
        let root = TempRoot::new();
        root.write(
            LOCAL_PANEL_CONFIG,
            r#"{
              "NATS_WEB_URL": "wss://nats.example", "NATS_DESKTOP_URL": "tls://nats.example:4222",
              "API_BASE_URL": "https://api.example", "AUTH_ISSUER": "https://auth.example/",
              "AUTH_DISCOVERY_DOCUMENT_URI": "https://auth.example/.well-known/openid-configuration",
              "AUTH_SCOPES": "openid",
              "AUTH_REDIRECT_URI": "http://localhost:2350/auth/back.html",
              "AUTH_POST_LOGOUT_REDIRECT_URI": "http://localhost:2350/auth/gone.html",
              "AUTH_FRONT_CHANNEL_LOGOUT_URI": "http://localhost:2350/auth/back.html?logout=front"
            }"#,
        );
        let mut facts = ci_clients();
        facts["panel_origin"] = "http://localhost:4000".into();
        let ci = CiClients::parse(&facts.to_string()).unwrap();

        let config =
            ClientConfiguration::ci_cluster(&root.ctx, &ci, root.path("users.json")).unwrap();

        let pages = &config.sign_in_pages;
        assert_eq!(
            pages["AUTH_REDIRECT_URI"],
            "http://localhost:4000/auth/back.html"
        );
        assert_eq!(
            pages["AUTH_POST_LOGOUT_REDIRECT_URI"],
            "http://localhost:4000/auth/gone.html"
        );
        assert_eq!(
            pages["AUTH_FRONT_CHANNEL_LOGOUT_URI"],
            "http://localhost:4000/auth/back.html?logout=front"
        );
    }

    #[test]
    fn a_link_port_replaces_the_port_a_url_names_or_is_added_to_one_without() {
        assert_eq!(
            with_port("tls://nats.example.com:4222", 14000),
            "tls://nats.example.com:14000"
        );
        assert_eq!(
            with_port("wss://nats.example.com", 18000),
            "wss://nats.example.com:18000"
        );
        assert_eq!(
            with_port("https://api.example.com/v1", 8443),
            "https://api.example.com:8443/v1"
        );
    }
}
