use std::time::{Duration, SystemTime, UNIX_EPOCH};

use base64::Engine;
use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use jose::{
    JsonWebKey, Jwt,
    jwk::JwkSigner,
    jws::{IntoPayload, PayloadData, PayloadKind},
    policy::{Checkable, StandardPolicy},
};
use nats_jwt_rs::{
    Claims,
    authorization::{AuthRequest, AuthResponse},
    user::User,
};
use nkeys::KeyPair;
use typewriter_component_test::prelude::SkirMessagingExpectationExt;
use wasmcloud_utils::skir::base::access::v1::permission::{
    EntityPermissionQualifier, EntityPermissionQualifier_User, GetEntityPermissionResponse,
    Permission, Permissions,
};

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

const PUBLIC_JWK: &str = r#"{
    "use": "sig",
    "kty": "OKP",
    "kid": "fixture-key",
    "crv": "Ed25519",
    "alg": "EdDSA",
    "x": "etkJX1EBhliHzBaimUQb0h2JhJKQ3G0beRVR3ssiedY",
    "key_ops": ["verify"]
}"#;

struct IdentityProvider;

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

#[component_fixture(
    id = "auth-callout",
    primary(package = "auth-callout", target = "auth_callout"),
    affected_paths("backend/access/auth-callout/")
)]
pub struct AuthCallout;

impl FixtureSpec for AuthCallout {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        let response_issuer = KeyPair::new_account();
        let user_signer = KeyPair::new_account();
        let nats_account = KeyPair::new_account();
        let issuers = serde_json::json!([{
            "id": "typewriter-panel",
            "issuer_url": "https://issuer.test/",
            "jwks_url": "http://issuer.test:8080/identity/keys?tenant=panel",
            "audiences": ["typewriter-panel", "typewriter-shared"],
            "require_expiration": true,
            "clock_skew_seconds": 30,
            "nats_account_key": nats_account.public_key()
        }]);
        let signing_keys = serde_json::json!({
            "typewriter-panel": user_signer.seed().expect("fixture user signer has a seed")
        });

        builder
            .messaging_subscription("$SYS.REQ.USER.AUTH")
            .otel()
            .outgoing_http::<IdentityProvider>("http://issuer.test:8080")
            .primary(|component| {
                component
                    .secret_environment(
                        "NATS_ISSUER_SEED",
                        response_issuer
                            .seed()
                            .expect("fixture response issuer has a seed"),
                    )
                    .secret_environment("NATS_SIGNING_KEYS", signing_keys.to_string())
                    .environment("ISSUERS", issuers.to_string())
            })
    }
}

fn external_jwt(name: Option<&str>) -> anyhow::Result<String> {
    external_jwt_with_claims(name, serde_json::json!({}))
}

fn external_jwt_with_claims(
    name: Option<&str>,
    overrides: serde_json::Value,
) -> anyhow::Result<String> {
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
    if let Some(name) = name {
        claims["name"] = name.into();
    }
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

fn auth_request(password: Option<String>) -> anyhow::Result<Vec<u8>> {
    let server = KeyPair::new_server();
    let user = KeyPair::new_user();
    let qualifier = EntityPermissionQualifier::User(Box::new(EntityPermissionQualifier_User {
        organization_id: None,
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

async fn authorize(
    context: &TestContext<AuthCallout>,
    body: Vec<u8>,
) -> anyhow::Result<Claims<AuthResponse>> {
    let response = authorize_raw(context, body).await?;
    Claims::decode(std::str::from_utf8(&response)?)
}

async fn authorize_raw(
    context: &TestContext<AuthCallout>,
    body: Vec<u8>,
) -> anyhow::Result<Vec<u8>> {
    let response = context
        .messaging()?
        .request("$SYS.REQ.USER.AUTH", body, Duration::from_secs(2))
        .await?;
    Ok(response)
}

fn authorization_payload(response: &[u8]) -> anyhow::Result<serde_json::Value> {
    let encoded = std::str::from_utf8(response)?;
    let payload = encoded
        .split('.')
        .nth(1)
        .ok_or_else(|| anyhow::anyhow!("authorization response has no payload"))?;
    let decoded = base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(payload)?;
    Ok(serde_json::from_slice(&decoded)?)
}

fn expect_jwks(context: &TestContext<AuthCallout>) -> anyhow::Result<()> {
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

fn expect_permissions(context: &TestContext<AuthCallout>) -> anyhow::Result<()> {
    let permission_response = GetEntityPermissionResponse {
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
            response: None,
            _unrecognized: None,
        },
        tags: vec!["user:panel_user".into()],
        _unrecognized: None,
    };
    context
        .messaging_mock()?
        .expect_request("auth.permissions.typewriter-panel")
        .reply_skir(
            &permission_response,
            GetEntityPermissionResponse::serializer(),
        );
    Ok(())
}

#[component_test(AuthCallout)]
async fn missing_user_token_returns_signed_denial(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    let response = authorize(context, auth_request(None)?).await?;

    assert_eq!(response.payload().error, "user not authorized");
    assert!(response.payload().jwt.is_empty());
    Ok(())
}

#[component_test(AuthCallout)]
async fn rejected_user_token_returns_signed_denial(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    let response = authorize(context, auth_request(Some("not-a-jwt".into()))?).await?;

    assert_eq!(response.payload().error, "user not authorized");
    assert!(response.payload().jwt.is_empty());
    Ok(())
}

#[component_test(AuthCallout)]
async fn valid_user_token_receives_signed_permissions(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    expect_permissions(context)?;

    let response = authorize_raw(
        context,
        auth_request(Some(external_jwt(Some("Panel User"))?))?,
    )
    .await?;
    let payload = authorization_payload(&response)?;

    assert!(payload["nats"].get("error").is_none_or(|error| error == ""));
    let user_jwt = payload["nats"]["jwt"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("authorization response jwt missing"))?;
    let user_claims = Claims::<User>::decode(user_jwt)?;
    assert_eq!(user_claims.name.as_deref(), Some("Panel User"));
    assert_eq!(
        user_claims.payload().permissions.permissions.publish.allow,
        ["cloud.to.user.panel_user.organization.watch"]
    );
    assert_eq!(
        user_claims.payload().generic_fields.tags,
        Some(vec!["user:panel_user".into()])
    );
    Ok(())
}

#[component_test(AuthCallout)]
async fn token_with_one_matching_audience_in_array_is_authorized(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    expect_permissions(context)?;
    let token = external_jwt_with_claims(
        Some("Panel User"),
        serde_json::json!({ "aud": ["unrelated", "typewriter-shared"] }),
    )?;

    let response = authorize_raw(context, auth_request(Some(token))?).await?;
    let payload = authorization_payload(&response)?;

    assert!(payload["nats"].get("error").is_none_or(|error| error == ""));
    assert!(
        payload["nats"]["jwt"]
            .as_str()
            .is_some_and(|jwt| !jwt.is_empty())
    );
    Ok(())
}

#[component_test(AuthCallout)]
async fn token_with_no_matching_audience_is_denied(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    let token = external_jwt_with_claims(
        Some("Panel User"),
        serde_json::json!({ "aud": ["unrelated", "also-unrelated"] }),
    )?;

    let response = authorize(context, auth_request(Some(token))?).await?;

    assert_eq!(response.payload().error, "user not authorized");
    assert!(response.payload().jwt.is_empty());
    Ok(())
}

#[component_test(AuthCallout)]
async fn user_token_without_name_receives_unknown_display_name(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    expect_permissions(context)?;

    let response = authorize_raw(context, auth_request(Some(external_jwt(None)?))?).await?;
    let payload = authorization_payload(&response)?;
    let user_jwt = payload["nats"]["jwt"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("authorization response jwt missing"))?;
    let user_claims = Claims::<User>::decode(user_jwt)?;

    assert_eq!(user_claims.name.as_deref(), Some("Unknown"));
    Ok(())
}

#[component_test(AuthCallout)]
async fn jwks_failure_does_not_issue_credentials(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    context
        .http_mock::<IdentityProvider>()?
        .expect()
        .get()
        .path_query("/identity/keys?tenant=panel")
        .status(http::StatusCode::SERVICE_UNAVAILABLE)
        .register()?;

    let result = authorize(
        context,
        auth_request(Some(external_jwt(Some("Panel User"))?))?,
    )
    .await;

    assert!(result.is_err());
    Ok(())
}

#[component_test(AuthCallout)]
async fn permission_exchange_failure_does_not_issue_credentials(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    context
        .messaging_mock()?
        .expect_request("auth.permissions.typewriter-panel")
        .reply_error("permission service unavailable");

    let result = authorize(
        context,
        auth_request(Some(external_jwt(Some("Panel User"))?))?,
    )
    .await;

    assert!(result.is_err());
    Ok(())
}

#[component_test(AuthCallout)]
async fn malformed_authorization_request_does_not_receive_response(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    let result = context
        .messaging()?
        .request(
            "$SYS.REQ.USER.AUTH",
            b"not a signed authorization request".to_vec(),
            Duration::from_millis(200),
        )
        .await;

    assert!(result.is_err());
    Ok(())
}
