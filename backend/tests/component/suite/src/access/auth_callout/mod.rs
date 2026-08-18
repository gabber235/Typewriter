use std::time::Duration;

use base64::Engine;
use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use jose::{
    JsonWebKey, Jwt, UntypedAdditionalProperties,
    jwk::JwkSigner,
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

const JWK: &str = r#"{
    "kty": "oct",
    "k": "MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDE",
    "kid": "fixture-key",
    "alg": "HS256",
    "key_ops": ["sign", "verify"]
}"#;

struct IdentityProvider;

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
            "issuer_url": "https://issuer.test",
            "jwks_url": "http://issuer.test/jwks",
            "nats_account_key": nats_account.public_key()
        }]);
        let signing_keys = serde_json::json!({
            "typewriter-panel": user_signer.seed().expect("fixture user signer has a seed")
        });

        builder
            .messaging_subscription("$SYS.REQ.USER.AUTH")
            .otel()
            .outgoing_http::<IdentityProvider>("http://issuer.test")
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
    let key: JsonWebKey = serde_json::from_str(JWK)?;
    let checked = key
        .check(StandardPolicy::default())
        .map_err(|(_, error)| anyhow::anyhow!(error.to_string()))?;
    let mut signer: JwkSigner = checked.try_into()?;
    let mut claims = serde_json::json!({
        "iss": "https://issuer.test",
        "sub": "panel_user"
    });
    if let Some(name) = name {
        claims["name"] = name.into();
    }
    let claims: jose::jwt::Claims<UntypedAdditionalProperties> = serde_json::from_value(claims)?;
    let jwt = Jwt::builder_jwt().build(claims)?.sign(&mut signer)?;
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
    let key: serde_json::Value = serde_json::from_str(JWK)?;
    context
        .http_mock::<IdentityProvider>()?
        .expect()
        .get()
        .path_query("/jwks")
        .response_json(&serde_json::json!({ "keys": [key] }))?
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
        .path_query("/jwks")
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
