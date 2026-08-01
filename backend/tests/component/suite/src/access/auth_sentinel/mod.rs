use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use wasmcloud_utils::{
    skir::base::access::v1::sentinel::GetSentinelCredentialsResponse,
    skir_client::UnrecognizedValues,
};

const CREDENTIALS: &str = "-----BEGIN NATS USER JWT-----\nfixture.jwt.value\n------END NATS USER JWT------\n-----BEGIN USER NKEY SEED-----\nSUFIXTURESEED\n------END USER NKEY SEED------";

#[component_fixture(
    id = "auth-sentinel",
    primary(package = "auth-sentinel", target = "auth_sentinel"),
    affected_paths("backend/access/auth-sentinel/")
)]
pub struct AuthSentinel;

impl FixtureSpec for AuthSentinel {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .http("auth-sentinel.test")
            .otel()
            .primary(|component| component.secret_environment("NATS_SENTINEL_CREDS", CREDENTIALS))
    }
}

#[component_test(AuthSentinel)]
async fn configured_credentials_are_returned(
    context: &mut TestContext<AuthSentinel>,
) -> TestResult {
    let response = context
        .http()?
        .get("/auth/sentinel?source=component-test")
        .send()
        .await?;

    assert_eq!(response.status(), http::StatusCode::OK);
    assert_eq!(
        response.headers().get(http::header::CONTENT_TYPE),
        Some(&http::HeaderValue::from_static("application/octet-stream")),
    );
    assert_eq!(
        response.headers().get("x-typewriter-format"),
        Some(&http::HeaderValue::from_static("skir-binary")),
    );
    let body = response.bytes().await?;
    let response =
        GetSentinelCredentialsResponse::serializer().from_bytes(&body, UnrecognizedValues::Drop)?;
    let GetSentinelCredentialsResponse::Success(credentials) = response else {
        anyhow::bail!("expected successful sentinel credentials response");
    };
    assert_eq!(credentials.jwt, "fixture.jwt.value");
    assert_eq!(credentials.seed, "SUFIXTURESEED");
    Ok(())
}

#[component_test(AuthSentinel)]
async fn unknown_path_is_rejected(context: &mut TestContext<AuthSentinel>) -> TestResult {
    let response = context.http()?.get("/unknown").send().await?;

    assert_eq!(response.status(), http::StatusCode::NOT_FOUND);
    assert_eq!(response.text().await?, "not found\n");
    Ok(())
}

#[component_test(AuthSentinel)]
async fn unsupported_method_is_rejected(context: &mut TestContext<AuthSentinel>) -> TestResult {
    let response = context
        .http()?
        .post("/auth/sentinel", Vec::new())
        .send()
        .await?;

    assert_eq!(response.status(), http::StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(response.text().await?, "method not allowed\n");
    Ok(())
}
