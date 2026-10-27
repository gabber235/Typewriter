use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use nkeys::KeyPair;
use typewriter_component_test::{access::PANEL_POLICY, callout::*, prelude::*};
use wasmcloud_utils::skir::base::access::v1::permission::GetEntityPermissionResponse;

#[component_fixture(
    id = "auth-callout",
    primary(package = "auth-callout", target = "auth_callout")
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
        auth_request(Some(external_jwt(
            serde_json::json!({ "name": "Panel User" }),
        )?))?,
    )
    .await?;
    let payload = authorization_payload(&response)?;

    assert!(payload["nats"].get("error").is_none_or(|error| error == ""));
    let user_jwt = payload["nats"]["jwt"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("authorization response jwt missing"))?;
    let user_claims = signed_claims(user_jwt)?;
    assert_eq!(user_claims["name"], "Panel User");
    assert_eq!(
        user_claims["nats"]["pub"]["allow"],
        serde_json::json!(["cloud.to.user.panel_user.organization.watch"])
    );
    assert_eq!(user_claims["nats"]["resp"]["max"], 1);
    assert_eq!(user_claims["nats"]["resp"]["ttl"], 300_000_000_000_u64);
    assert_eq!(
        user_claims["nats"]["tags"],
        serde_json::json!(["user:panel_user"])
    );
    Ok(())
}

#[component_test(AuthCallout)]
async fn token_with_no_matching_audience_is_denied(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    let token = external_jwt(serde_json::json!({
        "name": "Panel User",
        "aud": ["unrelated", "also-unrelated"]
    }))?;

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

    let response = authorize_raw(
        context,
        auth_request(Some(external_jwt(serde_json::json!({}))?))?,
    )
    .await?;
    let payload = authorization_payload(&response)?;
    let user_jwt = payload["nats"]["jwt"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("authorization response jwt missing"))?;
    let user_claims = signed_claims(user_jwt)?;

    assert_eq!(user_claims["name"], "Unknown");
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

    assert_no_answer(
        context,
        auth_request(Some(external_jwt(
            serde_json::json!({ "name": "Panel User" }),
        )?))?,
    )
    .await
}

#[component_test(AuthCallout)]
async fn permission_exchange_failure_does_not_issue_credentials(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    context
        .messaging_mock()?
        .expect_request(PANEL_POLICY)
        .reply_error("permission service unavailable");

    assert_no_answer(
        context,
        auth_request(Some(external_jwt(
            serde_json::json!({ "name": "Panel User" }),
        )?))?,
    )
    .await
}

#[component_test(AuthCallout)]
async fn internal_permission_reply_does_not_issue_credentials(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    expect_jwks(context)?;
    context
        .messaging_mock()?
        .expect_request(PANEL_POLICY)
        .reply_skir(&GetEntityPermissionResponse::InternalError(Box::default()));

    // A resolver failure is an authorization failure, never an empty grant.
    assert_no_answer(
        context,
        auth_request(Some(external_jwt(
            serde_json::json!({ "name": "Panel User" }),
        )?))?,
    )
    .await
}

#[component_test(AuthCallout)]
async fn malformed_authorization_request_does_not_receive_response(
    context: &mut TestContext<AuthCallout>,
) -> TestResult {
    assert_no_answer(context, b"not a signed authorization request".to_vec()).await
}

#[component_test(AuthCallout)]
async fn forged_signature_is_denied(context: &mut TestContext<AuthCallout>) -> TestResult {
    expect_jwks(context)?;
    // The signature still belongs to the original claims; the claims now name someone else.
    let token = external_jwt(serde_json::json!({ "name": "Panel User" }))?;
    let segments = token.split('.').collect::<Vec<_>>();
    let [header, _, signature] = segments[..] else {
        anyhow::bail!("a signed token has three segments")
    };
    let forged_claims = external_jwt(serde_json::json!({
        "name": "Panel User",
        "sub": "someone_else"
    }))?;
    let forged_payload = forged_claims
        .split('.')
        .nth(1)
        .ok_or_else(|| anyhow::anyhow!("a signed token has a payload"))?;
    let forged = format!("{header}.{forged_payload}.{signature}");

    let response = authorize(context, auth_request(Some(forged))?).await?;

    assert_eq!(response.payload().error, "user not authorized");
    assert!(response.payload().jwt.is_empty());
    Ok(())
}

#[component_test(AuthCallout)]
async fn unknown_issuer_is_denied(context: &mut TestContext<AuthCallout>) -> TestResult {
    // No JWKS expectation: a token from an unconfigured issuer never makes the callout fetch keys.
    let token = external_jwt(serde_json::json!({
        "name": "Panel User",
        "iss": "https://unknown-issuer.test/"
    }))?;

    let response = authorize(context, auth_request(Some(token))?).await?;

    assert_eq!(response.payload().error, "user not authorized");
    assert!(response.payload().jwt.is_empty());
    Ok(())
}
