use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use json_matcher::{JsonMatcher, assert_jm, create_json_matcher};
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirHttpExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        service::{ServiceRole, ServiceRole_Engine},
    },
    skir_variant,
};

struct Authentik;

#[component_fixture(
    id = "service-identity",
    primary(package = "service-identity", target = "service_identity"),
    affected_paths(
        "backend/service/service-identity/",
        "backend/database/schema/service/"
    )
)]
pub struct ServiceIdentity;

impl FixtureSpec for ServiceIdentity {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .http("service-identity.test")
            .otel()
            .outgoing_http::<Authentik>("http://authentik.test")
            .primary(|component| {
                component
                    .environment("AUTHENTIK_URL", "http://authentik.test")
                    .secret_environment("AUTHENTIK_TOKEN", "fixture-token")
            })
            .typewriter_database(SchemaPreset::Service)
    }
}

#[component_test(ServiceIdentity)]
async fn issue_identity_with_empty_roles(context: &mut TestContext<ServiceIdentity>) -> TestResult {
    let request = IssueServiceIdentityRequest {
        roles: Vec::new(),
        _unrecognized: None,
    };
    let response = context
        .http()?
        .skir_post(
            "/service/identity/issue",
            &request,
            IssueServiceIdentityRequest::serializer(),
            IssueServiceIdentityResponse::serializer(),
        )
        .await?;

    assert_eq!(response.status.as_u16(), 400);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::RolesRequiredError(_)
    ));
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn issue_identity_with_engine_role(context: &mut TestContext<ServiceIdentity>) -> TestResult {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .header(
            http::header::AUTHORIZATION,
            http::HeaderValue::from_static("Bearer fixture-token"),
        )
        .body_matches(|body| {
            let Ok(json) = serde_json::from_slice::<serde_json::Value>(body) else {
                return false;
            };
            create_json_matcher!({
                "create_group": false,
                "expiring": false
            })
            .allow_unexpected_keys()
            .json_matches(&json)
            .is_empty()
        })
        .response_json(&serde_json::json!({
            "username": "fixture-user",
            "token": "issued-token",
            "user_uid": "fixture-service-uid",
            "user_pk": 314
        }))?
        .register()?;

    let request = IssueServiceIdentityRequest {
        roles: vec![skir_variant!(ServiceRole::Engine {
            version: "1".into(),
        })],
        _unrecognized: None,
    };
    let response = context
        .http()?
        .skir_post(
            "/service/identity/issue",
            &request,
            IssueServiceIdentityRequest::serializer(),
            IssueServiceIdentityResponse::serializer(),
        )
        .await?;

    assert_eq!(response.status.as_u16(), 200);
    assert!(matches!(
        response.body,
        IssueServiceIdentityResponse::Success(_)
    ));
    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    let services = database.query_json("SELECT id FROM service").await?;
    assert_jm!(services, [{ "id": "service:`fixture-service-uid`" }]);
    Ok(())
}
