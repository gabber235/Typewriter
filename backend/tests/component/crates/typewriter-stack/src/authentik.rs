//! The Authentik surface Typewriter calls, for the worktree stack only; never deployed.
//!
//! It serves OIDC discovery and JWKS per application, the token endpoint (the password grant the
//! panel's integration tests sign in with, and the client credentials grant with a service
//! account's username and app password that the loader's registrar uses, `OAuthHttpAdapter.kt`),
//! and the service account route `service-identity` calls. Tokens carry the claims Authentik's
//! scope mappings emit and are signed with an Ed25519 key generated per start.

use std::collections::HashMap;
use std::net::Ipv4Addr;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, AtomicI64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result};
use axum::extract::{Form, Json, Path, State};
use axum::http::{HeaderMap, StatusCode, header};
use axum::response::{IntoResponse, Response};
use axum::routing::{delete, get, post, put};
use base64::Engine as _;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use ed25519_dalek::{Signer as _, SigningKey};
use serde::Deserialize;
use serde_json::{Value, json};
use tokio::net::TcpListener;

#[derive(clap::Args)]
pub struct IdentityArgs {
    /// The fixture users (`backend/tests/component/fixtures/stack-users.json`).
    #[arg(long)]
    users: PathBuf,
    #[arg(long)]
    identity: u16,
}

/// The API token `service-identity` presents (`AUTHENTIK_TOKEN`).
pub const API_TOKEN: &str = "stack-authentik-token";
const KEY_ID: &str = "stack";
const TOKEN_LIFETIME_SECONDS: u64 = 3600;

pub async fn run(args: IdentityArgs) -> Result<()> {
    let users: Vec<FixtureUser> = serde_json::from_str(
        &std::fs::read_to_string(&args.users)
            .with_context(|| format!("cannot read {}", args.users.display()))?,
    )
    .with_context(|| format!("{} is not a user list", args.users.display()))?;
    let mut seed = [0; 32];
    getrandom::getrandom(&mut seed).context("generating the signing key")?;
    let stand_in = Arc::new(AuthentikStandIn {
        base: format!("http://127.0.0.1:{}", args.identity),
        signing: SigningKey::from_bytes(&seed),
        users,
        service_accounts: Mutex::default(),
        next_account: AtomicI64::new(1),
        outage: AtomicBool::new(false),
    });
    let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, args.identity)).await?;
    axum::serve(listener, stand_in.router())
        .with_graceful_shutdown(crate::shutdown_signal())
        .await?;
    Ok(())
}

/// A person the stack knows, shared with the panel tests.
#[derive(Deserialize)]
struct FixtureUser {
    username: String,
    password: String,
    subject: String,
}

/// A service account `service-identity` created; it signs in with its username and app password.
struct ServiceAccount {
    token: String,
    uid: String,
}

struct AuthentikStandIn {
    base: String,
    signing: SigningKey,
    users: Vec<FixtureUser>,
    service_accounts: Mutex<HashMap<String, ServiceAccount>>,
    next_account: AtomicI64,
    /// Set by failure scenarios through `PUT /stack/outage`.
    outage: AtomicBool,
}

/// The grants the stack accepts; anything else fails deserialization.
#[derive(Deserialize)]
#[serde(tag = "grant_type", rename_all = "snake_case")]
enum TokenRequest {
    /// Panel sign in in integration tests.
    Password {
        username: String,
        password: String,
        client_id: String,
    },
    /// The loader's registrar: a service account's username and app password.
    ClientCredentials {
        username: String,
        password: String,
        client_id: String,
    },
}

#[derive(Deserialize)]
struct CreateServiceAccount {
    name: String,
}

type Shared = State<Arc<AuthentikStandIn>>;

impl AuthentikStandIn {
    fn router(self: Arc<Self>) -> axum::Router {
        axum::Router::new()
            .route(
                "/application/o/{app}/.well-known/openid-configuration",
                get(Self::discovery),
            )
            .route("/application/o/{app}/jwks/", get(Self::jwks))
            .route("/application/o/token/", post(Self::token))
            .route(
                "/api/v3/core/users/service_account/",
                post(Self::create_service_account),
            )
            .route("/api/v3/core/users/{pk}/", delete(Self::delete_user))
            .route("/stack/outage", put(Self::set_outage))
            .with_state(self)
    }

    fn issuer(&self, app: &str) -> String {
        format!("{}/application/o/{app}/", self.base)
    }

    async fn discovery(State(this): Shared, Path(app): Path<String>) -> Json<Value> {
        let issuer = this.issuer(&app);
        Json(json!({
            "issuer": issuer,
            "authorization_endpoint": format!("{}/application/o/authorize/", this.base),
            "token_endpoint": format!("{}/application/o/token/", this.base),
            "userinfo_endpoint": format!("{}/application/o/userinfo/", this.base),
            "end_session_endpoint": format!("{issuer}end-session/"),
            "jwks_uri": format!("{issuer}jwks/"),
            "response_types_supported": ["code"],
            "grant_types_supported": ["authorization_code", "password", "client_credentials"],
            "subject_types_supported": ["public"],
            "id_token_signing_alg_values_supported": ["EdDSA"],
            "scopes_supported": ["openid", "profile", "email", "entitlements"],
            "code_challenge_methods_supported": ["S256"],
        }))
    }

    async fn jwks(State(this): Shared) -> Json<Value> {
        let public = URL_SAFE_NO_PAD.encode(this.signing.verifying_key().to_bytes());
        Json(json!({
            "keys": [{ "kty": "OKP", "crv": "Ed25519", "alg": "EdDSA", "use": "sig", "kid": KEY_ID, "x": public }]
        }))
    }

    async fn token(State(this): Shared, Form(request): Form<TokenRequest>) -> Response {
        if this.outage.load(Ordering::Relaxed) {
            return oauth_error(StatusCode::SERVICE_UNAVAILABLE, "temporarily_unavailable");
        }
        let signed_in = match request {
            TokenRequest::Password {
                username,
                password,
                client_id,
            } => this
                .users
                .iter()
                .find(|user| user.username == username && user.password == password)
                .map(|user| (user.subject.clone(), user.username.clone(), client_id)),
            TokenRequest::ClientCredentials {
                username,
                password,
                client_id,
            } => this
                .service_accounts
                .lock()
                .expect("service accounts lock")
                .get(&username)
                .filter(|account| account.token == password)
                .map(|account| (account.uid.clone(), username.clone(), client_id)),
        };
        let Some((subject, username, client_id)) = signed_in else {
            return oauth_error(StatusCode::BAD_REQUEST, "invalid_grant");
        };
        match this.issue(&subject, &username, &client_id) {
            Ok(token) => Json(json!({
                "access_token": token,
                "id_token": token,
                "token_type": "Bearer",
                "expires_in": TOKEN_LIFETIME_SECONDS,
                "scope": "openid profile email entitlements",
            }))
            .into_response(),
            Err(error) => (StatusCode::INTERNAL_SERVER_ERROR, format!("{error:#}")).into_response(),
        }
    }

    /// A JWT with the claims Authentik's default scope mappings emit.
    fn issue(&self, subject: &str, username: &str, client_id: &str) -> Result<String> {
        let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
        let header = json!({ "alg": "EdDSA", "typ": "JWT", "kid": KEY_ID });
        let claims = json!({
            "iss": self.issuer(client_id),
            "sub": subject,
            "aud": client_id,
            "azp": client_id,
            "exp": now + TOKEN_LIFETIME_SECONDS,
            "iat": now,
            "nbf": now,
            "auth_time": now,
            "name": username,
            "preferred_username": username,
            "nickname": username,
            "email": format!("{username}@stack.typewriter.test"),
            "email_verified": true,
            "groups": [],
        });
        let signing_input = format!(
            "{}.{}",
            URL_SAFE_NO_PAD.encode(serde_json::to_vec(&header)?),
            URL_SAFE_NO_PAD.encode(serde_json::to_vec(&claims)?)
        );
        let signature = self.signing.sign(signing_input.as_bytes());
        Ok(format!(
            "{signing_input}.{}",
            URL_SAFE_NO_PAD.encode(signature.to_bytes())
        ))
    }

    async fn create_service_account(
        State(this): Shared,
        headers: HeaderMap,
        Json(request): Json<CreateServiceAccount>,
    ) -> Response {
        if !authorized(&headers) {
            return StatusCode::FORBIDDEN.into_response();
        }
        let pk = this.next_account.fetch_add(1, Ordering::Relaxed);
        let mut secret = [0; 24];
        if getrandom::getrandom(&mut secret).is_err() {
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
        let token = URL_SAFE_NO_PAD.encode(secret);
        let uid = format!("service-account-{pk}");
        this.service_accounts
            .lock()
            .expect("service accounts lock")
            .insert(
                request.name.clone(),
                ServiceAccount {
                    token: token.clone(),
                    uid: uid.clone(),
                },
            );
        Json(json!({ "username": request.name, "token": token, "user_uid": uid, "user_pk": pk }))
            .into_response()
    }

    async fn delete_user(
        State(this): Shared,
        headers: HeaderMap,
        Path(pk): Path<i64>,
    ) -> StatusCode {
        if !authorized(&headers) {
            return StatusCode::FORBIDDEN;
        }
        let uid = format!("service-account-{pk}");
        this.service_accounts
            .lock()
            .expect("service accounts lock")
            .retain(|_, account| account.uid != uid);
        StatusCode::NO_CONTENT
    }

    /// `PUT /stack/outage` with `true` makes sign in fail as if Authentik were down.
    async fn set_outage(State(this): Shared, Json(outage): Json<bool>) -> StatusCode {
        this.outage.store(outage, Ordering::Relaxed);
        StatusCode::NO_CONTENT
    }
}

fn authorized(headers: &HeaderMap) -> bool {
    headers
        .get(header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .is_some_and(|value| value == format!("Bearer {API_TOKEN}"))
}

fn oauth_error(status: StatusCode, error: &str) -> Response {
    (status, Json(json!({ "error": error }))).into_response()
}
