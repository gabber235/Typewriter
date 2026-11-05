//! A signed in person on the stack, connected the way the panel connects
//! (`panel/lib/infrastructure/messaging/nats_connection.dart`): a password grant against the
//! identity stand in, the sentinel credentials from the public HTTP route, and a NATS connection
//! the auth callout authorizes from the access token and the entity permission qualifier. Requests
//! are Skir payloads on the panel's `cloud.to` subjects, which the broker bridges to the
//! components.

use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use anyhow::{Context as _, Result, anyhow, bail};
use base64::Engine as _;
use base64::engine::general_purpose::STANDARD;
use futures_util::StreamExt as _;
use nkeys::KeyPair;
use serde::Deserialize;
use wasmcloud_utils::skir::base::access::v1::permission::{
    EntityPermissionQualifier, EntityPermissionQualifier_User,
};
use wasmcloud_utils::skir::base::access::v1::sentinel::GetSentinelCredentialsResponse;
use wasmcloud_utils::skir::base::kernel::v1::record_id::{RecordId, RecordIdKey};
use wasmcloud_utils::skir_client::UnrecognizedValues;
use wasmcloud_utils::transport::{ConnectionSession, RequestRoute, SubjectToken};
use wasmcloud_utils::transport_routes::panel_reply_inbox_prefix;

/// The OAuth application the panel signs in with.
const PANEL_CLIENT_ID: &str = "typewriter-panel";
const REQUEST_TIMEOUT: Duration = Duration::from_secs(10);

/// Where a signed in person reaches the stack.
#[derive(clap::Args)]
pub struct StackEndpoints {
    /// The fixture users (`backend/tests/component/fixtures/stack-users.json`).
    #[arg(long)]
    pub users: PathBuf,
    /// The stack's state directory.
    #[arg(long)]
    pub state: PathBuf,
    /// The identity stand in.
    #[arg(long)]
    pub identity: u16,
    /// The public HTTP routes.
    #[arg(long)]
    pub http: u16,
    /// The broker's client port.
    #[arg(long)]
    pub nats: u16,
}

/// A person the stack knows.
#[derive(Deserialize)]
pub struct FixtureUser {
    pub username: String,
    pub password: String,
    pub subject: String,
    /// Names of the organizations the person belongs to once the stack is provisioned.
    pub organizations: Vec<String>,
}

impl StackEndpoints {
    pub fn users(&self) -> Result<Vec<FixtureUser>> {
        serde_json::from_str(
            &std::fs::read_to_string(&self.users)
                .with_context(|| format!("cannot read {}", self.users.display()))?,
        )
        .with_context(|| format!("{} is not a user list", self.users.display()))
    }

    /// The stack's owner: the first fixture user who belongs to an organization.
    pub fn owner(&self) -> Result<FixtureUser> {
        self.users()?
            .into_iter()
            .find(|user| !user.organizations.is_empty())
            .with_context(|| format!("{} names no organization owner", self.users.display()))
    }

    /// Where `provision` records the organization it created, read by `bind` and xtask.
    pub fn provisioned_file(state: &Path) -> PathBuf {
        state.join("provisioned.json")
    }
}

/// One NATS connection of a signed in person, scoped to an organization or to the person alone.
pub struct Session {
    client: async_nats::Client,
    user: SubjectToken,
    organization: Option<SubjectToken>,
}

impl Session {
    pub async fn sign_in(
        endpoints: &StackEndpoints,
        user: &FixtureUser,
        organization: Option<&RecordId>,
    ) -> Result<Self> {
        let http = reqwest::Client::new();
        let token = access_token(&http, endpoints, user).await?;
        let sentinel = sentinel_credentials(&http, endpoints).await?;
        let session = connection_session()?;
        let qualifier = EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
            organization_id: organization.cloned(),
            connection_session: session.as_str().to_owned(),
            ..Default::default()
        }));
        let qualifier =
            STANDARD.encode(EntityPermissionQualifier::serializer().to_bytes(&qualifier));
        let user_token = token_of(&user.subject)?;
        let inbox = panel_reply_inbox_prefix(&user_token, &session);
        let key = Arc::new(KeyPair::from_seed(&sentinel.seed)?);
        let username = user.username.clone();
        let client = async_nats::ConnectOptions::with_auth_callback(move |nonce| {
            let (key, jwt, username, token, qualifier) = (
                key.clone(),
                sentinel.jwt.clone(),
                username.clone(),
                token.clone(),
                qualifier.clone(),
            );
            async move {
                let mut auth = async_nats::Auth::new();
                auth.jwt = Some(jwt);
                auth.signature = Some(key.sign(&nonce).map_err(async_nats::AuthError::new)?);
                auth.username = Some(username);
                auth.password = Some(token);
                auth.nkey = Some(qualifier);
                Ok(auth)
            }
        })
        .custom_inbox_prefix(inbox)
        .connect(format!("nats://127.0.0.1:{}", endpoints.nats))
        .await
        .with_context(|| {
            format!(
                "connecting {} to NATS through the auth callout",
                user.username
            )
        })?;
        Ok(Self {
            client,
            user: user_token,
            organization: organization.map(record_token).transpose()?,
        })
    }

    pub fn user(&self) -> &SubjectToken {
        &self.user
    }

    /// The organization this session is scoped to.
    pub fn organization(&self) -> Result<&SubjectToken> {
        self.organization
            .as_ref()
            .context("the session is not scoped to an organization")
    }

    /// Sends `request` on route `R` at `subject` and decodes its response.
    pub async fn request<R: RequestRoute>(
        &self,
        subject: String,
        request: &R::Request,
    ) -> Result<R::Response> {
        let method = R::method();
        // Panel connections may only receive replies on single tokens below their inbox prefix,
        // so each request gets its own inbox instead of async-nats' multiplexed one.
        let inbox = self.client.new_inbox();
        let mut replies = self
            .client
            .subscribe(inbox.clone())
            .await
            .with_context(|| format!("subscribing to the reply inbox of {subject}"))?;
        self.client
            .publish_with_reply(
                subject.clone(),
                inbox,
                method.request_serializer.to_bytes(request).into(),
            )
            .await
            .with_context(|| format!("requesting {subject}"))?;
        let reply = tokio::time::timeout(REQUEST_TIMEOUT, replies.next())
            .await
            .with_context(|| {
                format!(
                    "{subject} did not answer within {}s",
                    REQUEST_TIMEOUT.as_secs()
                )
            })?
            .with_context(|| format!("the reply inbox of {subject} closed"))?;
        if reply.status == Some(async_nats::StatusCode::NO_RESPONDERS) {
            bail!("nothing serves {subject}");
        }
        method
            .response_serializer
            .from_bytes(&reply.payload, UnrecognizedValues::Drop)
            .with_context(|| format!("{subject} answered with an unreadable response"))
    }
}

/// Signs `user` in with the password grant, as the panel's integration tests do.
async fn access_token(
    http: &reqwest::Client,
    endpoints: &StackEndpoints,
    user: &FixtureUser,
) -> Result<String> {
    #[derive(Deserialize)]
    struct Token {
        access_token: String,
    }
    let response = http
        .post(format!(
            "http://127.0.0.1:{}/application/o/token/",
            endpoints.identity
        ))
        .form(&[
            ("grant_type", "password"),
            ("username", &user.username),
            ("password", &user.password),
            ("client_id", PANEL_CLIENT_ID),
        ])
        .send()
        .await
        .context("signing in with the identity stand in")?;
    if !response.status().is_success() {
        bail!(
            "the identity stand in refused {}: {}",
            user.username,
            response.text().await.unwrap_or_default()
        );
    }
    Ok(response.json::<Token>().await?.access_token)
}

struct Sentinel {
    jwt: String,
    seed: String,
}

/// The bootstrap credentials every client connects with before the callout authorizes it.
async fn sentinel_credentials(
    http: &reqwest::Client,
    endpoints: &StackEndpoints,
) -> Result<Sentinel> {
    let response = http
        .get(format!("http://127.0.0.1:{}/auth/sentinel", endpoints.http))
        .send()
        .await
        .context("fetching the sentinel credentials")?;
    if !response.status().is_success() {
        bail!("/auth/sentinel answered {}", response.status());
    }
    match GetSentinelCredentialsResponse::serializer()
        .from_bytes(&response.bytes().await?, UnrecognizedValues::Drop)
        .context("/auth/sentinel answered with an unreadable response")?
    {
        GetSentinelCredentialsResponse::Success(success) => Ok(Sentinel {
            jwt: success.jwt,
            seed: success.seed,
        }),
        other => bail!("/auth/sentinel failed: {other:?}"),
    }
}

/// A fresh 32 character lowercase hexadecimal connection session, as the panel chooses one.
fn connection_session() -> Result<ConnectionSession> {
    let mut bytes = [0; 16];
    getrandom::getrandom(&mut bytes).context("generating a connection session")?;
    let session: String = bytes.iter().map(|byte| format!("{byte:02x}")).collect();
    ConnectionSession::try_from(session.as_str()).map_err(|error| anyhow!("{error}"))
}

pub fn token_of(value: &str) -> Result<SubjectToken> {
    SubjectToken::try_from(value).map_err(|error| anyhow!("`{value}` is no subject token: {error}"))
}

/// The subject token of a record, its string key, as the panel derives it.
pub fn record_token(record: &RecordId) -> Result<SubjectToken> {
    match &record.key {
        RecordIdKey::String(key) => token_of(key),
        _ => bail!("record {record} has no string key"),
    }
}
