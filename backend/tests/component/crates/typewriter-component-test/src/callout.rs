//! The auth callout's test kit: signed authorization requests, the identity provider's keys, and
//! the permission replies the callout receives and answers with.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use base64::Engine;
use component_test::{TestContext, TestResult};
use jose::{
    JsonWebKey, Jwt,
    jwk::JwkSigner,
    jws::{IntoPayload, PayloadData, PayloadKind},
    policy::{Checkable, StandardPolicy},
};
use nats_jwt_rs::{
    Claims, ClaimsHeader,
    authorization::{AuthRequest, AuthResponse},
};
use nkeys::KeyPair;
use wasmcloud_utils::skir::base::{
    access::v1::permission::{
        EntityPermissionGrant, EntityPermissionQualifier, EntityPermissionQualifier_User,
        GetEntityPermissionResponse, Permission, Permissions, ResponsePermission,
    },
    kernel::v1::duration::Duration as SkirDuration,
};

use crate::{
    REQUEST_TIMEOUT, SkirMessagingExpectationExt,
    access::{PANEL_POLICY, SESSION},
};

/// The subject the callout answers authorization requests on.
const AUTHORIZATION_SUBJECT: &str = "$SYS.REQ.USER.AUTH";

/// The identity provider's signing key, which only the test holds.
const PRIVATE_JWK: &str = r#"{
    "use": "sig",
    "kty": "OKP",
    "kid": "fixture-key",
    "crv": "Ed25519",
    "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "d": "629kbTnU3Pgfkoq7zG9qe5LPuMi1PdaLcNo87nUya1I",
    "key_ops": ["sign", "verify"]
}"#;

/// The identity provider's published key.
const PUBLIC_JWK: &str = r#"{
    "use": "sig",
    "kty": "OKP",
    "kid": "fixture-key",
    "crv": "Ed25519",
    "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "key_ops": ["verify"]
}"#;

/// The identity provider whose keys the callout fetches. A fixture names its outgoing HTTP with
/// `outgoing_http::<IdentityProvider>`.
pub struct IdentityProvider;

struct JsonClaims(serde_json::Value);

impl IntoPayload for JsonClaims {
    type Error = serde_json::Error;

    fn into_payload(self) -> Result<PayloadKind, Self::Error> {
        let encoded = serde_json::to_vec(&self.0)?;
        Ok(PayloadKind::Attached(PayloadData::Standard(
            jose::Base64UrlString::encode(encoded),
        )))
    }
}

/// A panel token the identity provider signed: valid for five minutes, issued for the panel to
/// the subject `panel_user`, with each claim of `claims` added or replacing the default.
pub fn external_jwt(claims: serde_json::Value) -> anyhow::Result<String> {
    let overrides = claims;
    let key: JsonWebKey = serde_json::from_str(PRIVATE_JWK)?;
    let checked = key
        .check(StandardPolicy::default())
        .map_err(|(_, error)| anyhow::anyhow!(error.to_string()))?;
    let mut signer: JwkSigner = checked.try_into()?;
    let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
    let mut claims = serde_json::json!({
        "iss": "https://issuer.test/",
        "sub": "panel_user",
        "aud": "typewriter-panel",
        "exp": now + 300,
        "nbf": now - 1,
        "iat": now
    });
    for (key, value) in overrides
        .as_object()
        .expect("claim overrides are an object")
    {
        claims[key] = value.clone();
    }
    let jwt = Jwt::builder_jwt()
        .build(JsonClaims(claims))?
        .sign(&mut signer)?;
    Ok(jwt.encode().to_string())
}

/// A signed authorization request the broker sends when `panel_user` connects to the panel with
/// `password` as its token.
pub fn auth_request(password: Option<String>) -> anyhow::Result<Vec<u8>> {
    let server = KeyPair::new_server();
    let user = KeyPair::new_user();
    let qualifier = EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
        organization_id: None,
        connection_session: SESSION.into(),
        _unrecognized: None,
    }));
    let mut payload = AuthRequest::default();
    payload.server.id = server.public_key();
    payload.user_nkey = user.public_key();
    payload.connect_opts.user = Some("panel_user".into());
    payload.connect_opts.pass = password;
    payload.connect_opts.nkey = Some(
        base64::engine::general_purpose::STANDARD
            .encode(EntityPermissionQualifier::serializer().to_bytes(&qualifier)),
    );
    let claims = Claims {
        aud: Some("nats-authorization-request".into()),
        exp: None,
        iat: 0,
        id: None,
        iss: server.public_key(),
        jti: String::new(),
        name: None,
        nats: payload,
        nbf: None,
        sub: user.public_key(),
    };
    Ok(claims.encode(&server)?.into_bytes())
}

/// Sends an authorization request to the callout and decodes its signed answer.
pub async fn authorize<F>(
    context: &TestContext<F>,
    body: Vec<u8>,
) -> anyhow::Result<Claims<AuthResponse>> {
    let response = authorize_raw(context, body).await?;
    Claims::decode(std::str::from_utf8(&response)?)
}

/// Sends an authorization request to the callout and returns its answer undecoded.
pub async fn authorize_raw<F>(context: &TestContext<F>, body: Vec<u8>) -> anyhow::Result<Vec<u8>> {
    context
        .messaging()?
        .request(AUTHORIZATION_SUBJECT, body, REQUEST_TIMEOUT)
        .await
}

/// The claims of an authorization answer, read without checking its signature.
pub fn authorization_payload(response: &[u8]) -> anyhow::Result<serde_json::Value> {
    let encoded = std::str::from_utf8(response)?;
    let payload = encoded
        .split('.')
        .nth(1)
        .ok_or_else(|| anyhow::anyhow!("authorization response has no payload"))?;
    let decoded = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(payload)?;
    Ok(serde_json::from_slice(&decoded)?)
}

/// The claims of a NATS token, after checking that its issuer signed it.
pub fn signed_claims(token: &str) -> anyhow::Result<serde_json::Value> {
    let mut parts = token.split('.');
    let header = parts
        .next()
        .ok_or_else(|| anyhow::anyhow!("signed claims have no header"))?;
    let payload = parts
        .next()
        .ok_or_else(|| anyhow::anyhow!("signed claims have no payload"))?;
    let signature = parts
        .next()
        .ok_or_else(|| anyhow::anyhow!("signed claims have no signature"))?;
    if parts.next().is_some() {
        anyhow::bail!("signed claims have extra segments");
    }

    header.parse::<ClaimsHeader>()?;
    let decoded = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(payload)?;
    let claims: serde_json::Value = serde_json::from_slice(&decoded)?;
    let issuer = claims["iss"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("signed claims issuer missing"))?;
    let signature = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(signature)?;
    let signed = format!("{header}.{payload}");
    KeyPair::from_public_key(issuer)?.verify(signed.as_bytes(), &signature)?;
    Ok(claims)
}

/// The identity provider serves its keys once: a retired key and the one that signs
/// [`external_jwt`].
pub fn expect_jwks<F>(context: &TestContext<F>) -> anyhow::Result<()> {
    let current_key: serde_json::Value = serde_json::from_str(PUBLIC_JWK)?;
    let mut previous_key = current_key.clone();
    previous_key["kid"] = "previous-key".into();
    context
        .http_mock::<IdentityProvider>()?
        .expect()
        .get()
        .path_query("/identity/keys?tenant=panel")
        .response_json(&serde_json::json!({ "keys": [previous_key, current_key] }))?
        .register()
}

/// The permission component grants `panel_user` one route, one event, and a single reply that
/// lives five minutes.
pub fn expect_permissions<F>(context: &TestContext<F>) -> anyhow::Result<()> {
    let permission_response =
        GetEntityPermissionResponse::Granted(Box::new(EntityPermissionGrant {
            permissions: Permissions {
                publish: Permission {
                    allow: vec!["cloud.to.user.panel_user.organization.watch".into()],
                    deny: vec!["private.>".into()],
                    _unrecognized: None,
                },
                subscribe: Permission {
                    allow: vec!["cloud.from.user.panel_user.organization.watch".into()],
                    deny: Vec::new(),
                    _unrecognized: None,
                },
                response: Some(ResponsePermission {
                    max_messages: Some(1),
                    ttl: Some(SkirDuration {
                        milliseconds: 300_000,
                        _unrecognized: None,
                    }),
                    _unrecognized: None,
                }),
                _unrecognized: None,
            },
            tags: vec!["user:panel_user".into()],
            _unrecognized: None,
        }));
    context
        .messaging_mock()?
        .expect_request(PANEL_POLICY)
        .reply_skir(&permission_response);
    Ok(())
}

/// Sends an authorization request and asserts the callout stays silent. Without an answer the
/// server refuses the connection, so silence is how the callout withholds credentials when it
/// cannot decide.
pub async fn assert_no_answer<F>(context: &TestContext<F>, body: Vec<u8>) -> TestResult {
    let result = context
        .messaging()?
        .request(AUTHORIZATION_SUBJECT, body, Duration::from_secs(2))
        .await;

    let Err(error) = result else {
        anyhow::bail!("the callout answered instead of staying silent")
    };
    assert!(
        error
            .downcast_ref::<tokio::time::error::Elapsed>()
            .is_some(),
        "expected no answer, the request failed otherwise: {error:#}"
    );
    Ok(())
}
