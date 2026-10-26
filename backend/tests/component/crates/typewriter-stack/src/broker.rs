//! The stack's NATS: the same [`nats_broker::Broker`] the component tests use, on the stack's
//! fixed ports, with the cluster's two accounts (`platform/nats/terraform/main.tf` in the
//! infrastructure repository).
//!
//! WASMCLOUD holds the host's user, so every component, and the auth callout. Its only
//! `auth_users` entry is the host's user; anyone else, including a client holding the sentinel
//! credentials, is authorized by the callout, which places users in TYPEWRITER with that
//! account's signing key. The accounts bridge each other the way the cluster does: a request a
//! user publishes on `cloud.to.>` reaches the components as `typewriter.from.>`, and an event a
//! component publishes on `typewriter.to.>` reaches users as `cloud.from.>`. Keys persist in
//! `broker-keys`, the one directory a new run keeps, so credentials a tool cached in an earlier run
//! stay valid.

use std::collections::BTreeSet;
use std::net::Ipv4Addr;
use std::path::{Path, PathBuf};
use std::sync::Arc;

use anyhow::{Context as _, Result};
use axum::extract::{Json, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use indexmap::IndexSet;
use nats_broker::{Broker, Permissions, Ports, account_claims};
use nats_jwt_rs::account::ExternalAuthorization;
use nats_jwt_rs::types::{Export, ExportType, Import, Permission, ResponseType, SigningKey};
use nats_jwt_rs::user::User;
use nkeys::KeyPair;
use serde::{Deserialize, Serialize};
use tokio::net::TcpListener;

#[derive(clap::Args)]
pub struct BrokerArgs {
    /// The stack's state directory.
    #[arg(long)]
    state: PathBuf,
    #[arg(long)]
    nats: u16,
    #[arg(long)]
    websocket: u16,
    /// The account service, which hands tests isolated accounts.
    #[arg(long)]
    accounts: u16,
}

/// The JetStream stream membership events are published to, as the cluster defines it.
const MEMBERSHIP_STREAM: &str = "TYPEWRITER_MEMBERSHIP";
const MEMBERSHIP_SUBJECTS: [&str; 5] = [
    "cloud.from.organization.*.members.changed",
    "cloud.from.organization.*.join_requests.changed",
    "cloud.from.organization.*.join_codes.changed",
    "cloud.from.user.*.join_requests.changed",
    "cloud.from.user.*.organizations.changed",
];

/// Runs the broker and its account service until the supervisor stops it.
pub async fn run(args: BrokerArgs) -> Result<()> {
    let keys = StackKeys::load_or_create(&args.state.join("broker-keys"))?;
    let broker = Broker::start_with(
        KeyPair::from_seed(&keys.operator)?,
        KeyPair::from_seed(&keys.system)?,
        Ports {
            client: Some(args.nats),
            websocket: Some(args.websocket),
        },
    )
    .await?;
    let wasmcloud = KeyPair::from_seed(&keys.wasmcloud)?;
    let typewriter = KeyPair::from_seed(&keys.typewriter)?;
    let signing = KeyPair::from_seed(&keys.typewriter_signing)?;
    let host_user = KeyPair::new_user();

    let mut claims = account_claims("WASMCLOUD", &wasmcloud);
    let account = claims.payload_mut();
    account.exports = Some(vec![service_export("typewriter.from.>")]);
    account.imports = Some(vec![service_import(
        "cloud.from.>",
        &typewriter,
        "typewriter.to.>",
    )]);
    account.authorization = Some(ExternalAuthorization {
        auth_users: Some(BTreeSet::from([host_user.public_key()])),
        allowed_accounts: Some(BTreeSet::from([typewriter.public_key()])),
        xkey: None,
    });
    broker
        .install(claims)
        .await
        .context("installing the WASMCLOUD account")?;

    let mut claims = account_claims("TYPEWRITER", &typewriter);
    let account = claims.payload_mut();
    account.signing_keys = Some(IndexSet::from([SigningKey {
        key: signing.public_key(),
        scope: None,
    }]));
    account.exports = Some(vec![service_export("cloud.from.>")]);
    account.imports = Some(vec![service_import(
        "typewriter.from.>",
        &wasmcloud,
        "cloud.to.>",
    )]);
    broker
        .install(claims)
        .await
        .context("installing the TYPEWRITER account")?;

    let host = user_jwt(
        &wasmcloud,
        &host_user,
        "host",
        Permissions::default(),
        false,
    )?;
    let sentinel_user = KeyPair::new_user();
    let deny_all = Permissions {
        publish: Permission {
            allow: Vec::new(),
            deny: vec![">".into()],
        },
        subscribe: Permission {
            allow: Vec::new(),
            deny: vec![">".into()],
        },
        resp: None,
    };
    let sentinel = user_jwt(&wasmcloud, &sentinel_user, "sentinel", deny_all, true)?;
    let stream_manager = KeyPair::new_user();
    let stream_manager_jwt = user_jwt(
        &typewriter,
        &stream_manager,
        "membership-stream-manager",
        Permissions::default(),
        false,
    )?;
    create_membership_stream(broker.endpoint(), &stream_manager_jwt, &stream_manager).await?;

    BrokerConnection {
        endpoint: broker.endpoint().to_owned(),
        typewriter_account: typewriter.public_key(),
        host_jwt: host,
        host_seed: host_user.seed()?,
        sentinel_creds: creds_file(&sentinel, &sentinel_user.seed()?),
        callout_issuer_seed: keys.wasmcloud.clone(),
        typewriter_signing_seed: keys.typewriter_signing.clone(),
    }
    .write(&crate::broker_connection_file(&args.state))?;

    let service = axum::Router::new()
        .route("/ready", get(|| async { StatusCode::NO_CONTENT }))
        .route("/accounts", post(create_account))
        .with_state(Arc::new(broker));
    let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, args.accounts)).await?;
    axum::serve(listener, service)
        .with_graceful_shutdown(crate::shutdown_signal())
        .await?;
    Ok(())
}

/// `POST /accounts` with a permission set answers with the `.creds` text of a user holding
/// exactly those permissions in a new account of its own, so a Dart or Kotlin test gets an
/// isolated account without minting JWTs itself.
async fn create_account(
    State(broker): State<Arc<Broker>>,
    Json(permissions): Json<Permissions>,
) -> Response {
    let created = async {
        let account = broker.account().await?;
        anyhow::Ok(account.user(&permissions)?.to_creds_file())
    };
    match created.await {
        Ok(creds) => creds.into_response(),
        Err(error) => (StatusCode::INTERNAL_SERVER_ERROR, format!("{error:#}")).into_response(),
    }
}

/// A service export without activation tokens whose responses may stream, as in the cluster.
fn service_export(subject: &str) -> Export {
    Export {
        name: subject.trim_end_matches(".>").into(),
        subject: subject.into(),
        export_type: Some(ExportType::Service),
        token_req: Some(false),
        response_type: Some(ResponseType::Stream),
        ..Export::default()
    }
}

/// Imports `subject` exported by `account` under `local_subject`.
fn service_import(subject: &str, account: &KeyPair, local_subject: &str) -> Import {
    Import {
        name: subject.trim_end_matches(".>").into(),
        subject: subject.into(),
        account: account.public_key(),
        local_subject: local_subject.into(),
        export_type: Some(ExportType::Service),
        ..Import::default()
    }
}

async fn create_membership_stream(endpoint: &str, jwt: &str, user: &KeyPair) -> Result<()> {
    let seed = user.seed()?;
    let key = Arc::new(KeyPair::from_seed(&seed)?);
    let client = async_nats::ConnectOptions::with_jwt(jwt.to_owned(), move |nonce| {
        let key = key.clone();
        async move { key.sign(&nonce).map_err(async_nats::AuthError::new) }
    })
    .connect(endpoint)
    .await
    .context("connecting as the host user")?;
    async_nats::jetstream::new(client)
        .get_or_create_stream(async_nats::jetstream::stream::Config {
            name: MEMBERSHIP_STREAM.into(),
            subjects: MEMBERSHIP_SUBJECTS
                .iter()
                .map(|subject| (*subject).into())
                .collect(),
            storage: async_nats::jetstream::stream::StorageType::Memory,
            ..Default::default()
        })
        .await
        .context("creating the membership stream")?;
    Ok(())
}

fn user_jwt(
    account: &KeyPair,
    user: &KeyPair,
    name: &str,
    permissions: Permissions,
    bearer: bool,
) -> Result<String> {
    let mut claims = User::new_claims(name.into(), user.public_key());
    let payload = claims.payload_mut();
    payload.permissions.permissions = permissions;
    payload.permissions.bearer_token = bearer.then_some(true);
    claims.encode(account)
}

fn creds_file(jwt: &str, seed: &str) -> String {
    format!(
        "-----BEGIN NATS USER JWT-----\n{jwt}\n------END NATS USER JWT------\n\n\
         -----BEGIN USER NKEY SEED-----\n{seed}\n------END USER NKEY SEED------\n"
    )
}

/// The keys a stack keeps across runs, as seeds.
#[derive(Serialize, Deserialize)]
struct StackKeys {
    operator: String,
    system: String,
    /// The account of the components and the auth callout, which signs the callout's responses.
    wasmcloud: String,
    /// The account signed in users and services are placed in.
    typewriter: String,
    /// Signs the user JWTs the auth callout issues.
    typewriter_signing: String,
}

impl StackKeys {
    fn load_or_create(dir: &Path) -> Result<Self> {
        let file = dir.join("keys.json");
        if let Ok(text) = std::fs::read_to_string(&file) {
            return serde_json::from_str(&text)
                .with_context(|| format!("{} is not a key file", file.display()));
        }
        let keys = Self {
            operator: KeyPair::new_operator().seed()?,
            system: KeyPair::new_account().seed()?,
            wasmcloud: KeyPair::new_account().seed()?,
            typewriter: KeyPair::new_account().seed()?,
            typewriter_signing: KeyPair::new_account().seed()?,
        };
        write_private(&file, &serde_json::to_string_pretty(&keys)?)?;
        Ok(keys)
    }
}

/// What the host connects with, written by `broker` and read by `host`.
#[derive(Serialize, Deserialize)]
pub struct BrokerConnection {
    pub endpoint: String,
    pub typewriter_account: String,
    pub host_jwt: String,
    pub host_seed: String,
    pub sentinel_creds: String,
    /// Signs the callout's authorization responses (`NATS_ISSUER_SEED`).
    pub callout_issuer_seed: String,
    /// Signs the user JWTs the callout issues (`NATS_SIGNING_KEYS`).
    pub typewriter_signing_seed: String,
}

impl BrokerConnection {
    pub fn read(file: &Path) -> Result<Self> {
        let text = std::fs::read_to_string(file)
            .with_context(|| format!("cannot read {}", file.display()))?;
        serde_json::from_str(&text).with_context(|| format!("{} is unreadable", file.display()))
    }

    fn write(&self, file: &Path) -> Result<()> {
        write_private(file, &serde_json::to_string_pretty(self)?)
    }
}

/// Writes a file only its owner can read; it holds seeds.
fn write_private(file: &Path, contents: &str) -> Result<()> {
    use std::io::Write as _;
    use std::os::unix::fs::OpenOptionsExt as _;
    if let Some(parent) = file.parent() {
        std::fs::create_dir_all(parent)?;
    }
    std::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .mode(0o600)
        .open(file)
        .and_then(|mut handle| handle.write_all(contents.as_bytes()))
        .with_context(|| format!("cannot write {}", file.display()))
}
