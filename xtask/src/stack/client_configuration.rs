//! How clients reach a backend, in the two formats they read: `panel.json` for
//! `--dart-define-from-file` and `realm.properties` for `TYPEWRITER_CONFIG_FILE`. A worktree stack
//! and the CI cluster write the same keys, so scenarios read the same values in both tiers.

use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

use anyhow::{Context as _, Result};
use serde_json::Value;

use super::spec::StackContext;
use crate::Context;

/// The OAuth application the panel signs in with.
pub const PANEL_CLIENT_ID: &str = "typewriter-panel";
/// The OAuth application services and hosts sign in with.
pub const SERVICES_CLIENT_ID: &str = "typewriter-services";
/// The fixture users every stack knows, shared with the panel tests.
pub const FIXTURE_USERS: &str = "backend/tests/component/fixtures/stack-users.json";
/// The panel's configuration for Gabber's local cluster.
const LOCAL_PANEL_CONFIG: &str = "panel/config/local.json";

pub struct ClientConfiguration {
    /// Through the faults link on a stack, so scenarios can cut the panel's connection.
    pub nats_desktop_url: String,
    pub nats_web_url: String,
    /// What hosts connect to; a host is not behind the faults link.
    pub nats_host_url: String,
    pub api_base_url: String,
    pub auth_base_url: String,
    pub auth_issuer: String,
    pub auth_discovery_document_uri: String,
    /// Present only on a worktree stack; failure scenarios skip without it.
    pub stack: Option<StackControl>,
}

pub struct StackControl {
    /// The identity stand in, whose `/stack/outage` switch failure scenarios flip.
    pub identity_url: String,
    pub faults_url: String,
    pub accounts_url: String,
    pub users: Value,
}

impl ClientConfiguration {
    /// The worktree stack's addresses.
    pub fn worktree(ctx: &StackContext) -> Result<Self> {
        let identity = ctx.url("http", "identity");
        let users_file = ctx.root().join(FIXTURE_USERS);
        let users = serde_json::from_str(
            &fs::read_to_string(&users_file)
                .with_context(|| format!("cannot read {}", users_file.display()))?,
        )
        .with_context(|| format!("{} is not JSON", users_file.display()))?;
        Ok(Self {
            nats_desktop_url: ctx.url("nats", "nats-proxy"),
            nats_web_url: ctx.url("ws", "websocket"),
            nats_host_url: ctx.url("nats", "nats"),
            api_base_url: ctx.url("http", "http"),
            auth_base_url: identity.clone(),
            auth_issuer: format!("{identity}/application/o/{PANEL_CLIENT_ID}/"),
            auth_discovery_document_uri: format!(
                "{identity}/application/o/{PANEL_CLIENT_ID}/.well-known/openid-configuration"
            ),
            stack: Some(StackControl {
                identity_url: identity,
                faults_url: ctx.url("http", "faults"),
                accounts_url: ctx.url("http", "accounts"),
                users,
            }),
        })
    }

    /// The CI cluster's addresses. Its overlay is the local overlay with only decryption, images
    /// and resources swapped, so it answers on the addresses the panel's local configuration names.
    pub fn ci_cluster(ctx: &Context) -> Result<Self> {
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
        Ok(Self {
            nats_desktop_url: key("NATS_DESKTOP_URL")?,
            nats_web_url: key("NATS_WEB_URL")?,
            nats_host_url: key("NATS_DESKTOP_URL")?,
            api_base_url: key("API_BASE_URL")?,
            auth_base_url: issuer.trim_end_matches('/').to_owned(),
            auth_issuer: issuer,
            auth_discovery_document_uri: key("AUTH_DISCOVERY_DOCUMENT_URI")?,
            stack: None,
        })
    }

    pub fn write(&self, dir: &Path) -> Result<()> {
        let panel = dir.join("panel.json");
        fs::write(&panel, serde_json::to_string_pretty(&self.panel_defines())?)
            .with_context(|| format!("cannot write {}", panel.display()))?;
        let realm = dir.join("realm.properties");
        fs::write(&realm, self.realm_properties())
            .with_context(|| format!("cannot write {}", realm.display()))
    }

    /// Keys `AppConfig` reads (`panel/lib/shared/utilities/app_config.dart`), plus `STACK_*` for
    /// the test harness.
    fn panel_defines(&self) -> BTreeMap<&'static str, String> {
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
            ("OTEL_ENABLED", "false".into()),
        ]);
        if let Some(stack) = &self.stack {
            defines.extend([
                ("STACK_IDENTITY_URL", stack.identity_url.clone()),
                ("STACK_FAULTS_URL", stack.faults_url.clone()),
                ("STACK_ACCOUNTS_URL", stack.accounts_url.clone()),
                ("STACK_USERS", stack.users.to_string()),
            ]);
        }
        defines
    }

    /// The loader's settings (`services/runtime/loader/core/.../LoaderSettings.kt`), with the
    /// embedded Realm database `services/runtime/config/local.properties` uses.
    fn realm_properties(&self) -> String {
        let settings = [
            ("API_BASE_URL", self.api_base_url.as_str()),
            ("AUTH_BASE_URL", self.auth_base_url.as_str()),
            ("JWT_CLIENT_ID", SERVICES_CLIENT_ID),
            ("JWT_SCOPES", "openid profile entitlements"),
            ("NATS_URL", self.nats_host_url.as_str()),
            ("OTEL_TRACES_SAMPLER", "always_off"),
            ("REALM_DB_ENDPOINT_TYPE", "embedded"),
            ("REALM_DB_ENGINE", "surrealkv"),
            ("REALM_DB_PATH", "database/realm"),
            ("REALM_DB_NAMESPACE", "typewriter"),
            ("REALM_DB_DATABASE", "realm"),
            ("REALM_DB_AUTHENTICATION", "none"),
        ];
        settings
            .iter()
            .map(|(key, value)| format!("{key}={}\n", value.replace(':', "\\:")))
            .collect()
    }
}
