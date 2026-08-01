use std::time::Duration;

use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::{
    DatabaseHandle, SchemaPreset, SkirHttpExt, SkirMessagingExt, TypewriterFixtureBuilderExt,
};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        registration::{BindServiceRequest, BindServiceResponse},
        service::{ServiceRole, ServiceRole_Engine},
        status::{GetServiceStatusRequest, GetServiceStatusResponse, ServiceBinding},
    },
    skir_client::UnrecognizedValues,
    skir_variant,
};

struct Authentik;

#[component_fixture(
    id = "workflow-service-onboarding",
    primary(package = "service-identity", target = "service_identity"),
    dependency(package = "service-registration", target = "service_registration"),
    affected_paths(
        "backend/service/service-identity/",
        "backend/service/service-registration/",
        "backend/database/schema/service/",
        "backend/database/schema/organization/"
    )
)]
pub struct ServiceOnboarding;

impl FixtureSpec for ServiceOnboarding {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .http("service-identity.test")
            .outgoing_http::<Authentik>("http://authentik.test")
            .primary(|component| {
                component
                    .environment("AUTHENTIK_URL", "http://authentik.test")
                    .secret_environment("AUTHENTIK_TOKEN", "fixture-token")
            })
            .dependency("service-registration", |component| {
                component
                    .subscription("typewriter.from.service.*.status")
                    .subscription("typewriter.from.user.*.organization.*.services.*")
            })
            .messaging()
            .otel()
            .typewriter_database(SchemaPreset::Full)
    }
}

#[component_test(ServiceOnboarding)]
async fn issued_service_can_register_with_an_organization(
    context: &mut TestContext<ServiceOnboarding>,
) -> TestResult {
    context
        .http_mock::<Authentik>()?
        .expect()
        .post()
        .path_query("/api/v3/core/users/service_account/")
        .header(
            http::header::AUTHORIZATION,
            http::HeaderValue::from_static("Bearer fixture-token"),
        )
        .response_json(&serde_json::json!({
            "username": "onboarding-service",
            "token": "issued-token",
            "user_uid": "onboarding",
            "user_pk": 42
        }))?
        .register()?;
    let identity = context
        .http()?
        .skir_post(
            "/service/identity/issue",
            &IssueServiceIdentityRequest {
                roles: vec![skir_variant!(ServiceRole::Engine {
                    version: "1".into(),
                })],
                _unrecognized: None,
            },
            IssueServiceIdentityRequest::serializer(),
            IssueServiceIdentityResponse::serializer(),
        )
        .await?;
    assert!(matches!(
        identity.body,
        IssueServiceIdentityResponse::Success(ref success)
            if success.service_id == "onboarding"
    ));

    let database = context
        .extension::<DatabaseHandle>()
        .ok_or_else(|| anyhow::anyhow!("database handle missing"))?;
    database
        .execute(
            "CREATE user:owner SET name = 'owner'; CREATE organization:alpha SET name = 'alpha', founder = user:owner",
        )
        .await?;
    let status = context
        .messaging()?
        .request_skir(
            "typewriter.from.service.onboarding.status",
            &GetServiceStatusRequest::default(),
            GetServiceStatusRequest::serializer(),
            GetServiceStatusResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    let GetServiceStatusResponse::Status(status) = status else {
        anyhow::bail!("expected unbound service status");
    };
    let ServiceBinding::Unbound(binding) = status.binding else {
        anyhow::bail!("expected unbound service binding");
    };
    let registration_token = binding
        .registration_token
        .ok_or_else(|| anyhow::anyhow!("registration token missing"))?;

    context
        .messaging_mock()?
        .expect_publish("typewriter.to.organization.alpha.services.watch");
    context
        .messaging_mock()?
        .expect_publish("typewriter.to.service.onboarding.registration.bound");
    let binding = context
        .messaging()?
        .request_skir(
            "typewriter.from.user.owner.organization.alpha.services.bind",
            &BindServiceRequest {
                registration_token,
                _unrecognized: None,
            },
            BindServiceRequest::serializer(),
            BindServiceResponse::serializer(),
            Duration::from_secs(2),
            UnrecognizedValues::Drop,
        )
        .await?;
    assert!(matches!(
        binding,
        BindServiceResponse::Success(ref service) if service.service_id == "onboarding"
    ));
    let stored = database
        .query_json("SELECT VALUE organization FROM ONLY service:onboarding")
        .await?;
    assert_jm!(stored, "organization:alpha");
    Ok(())
}
