use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::{IssueServiceIdentityRequest, IssueServiceIdentityResponse},
        organization::OrganizationServicesChanged,
        registration::{BindServiceRequest, BindServiceResponse, ServiceBoundNotification},
        service::{ServiceRole, ServiceRole_Host},
        status::{EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse},
    },
    skir_variant,
    transport_routes::service_registration,
};

struct Authentik;

#[component_fixture(
    id = "workflow-service-onboarding",
    primary(package = "service-identity", target = "service_identity"),
    dependency(package = "service-registration", target = "service_registration")
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
                component.subscriptions(service_registration::SUBSCRIPTIONS)
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
        .skir_post::<_, IssueServiceIdentityResponse>(
            "/service/identity/issue",
            &IssueServiceIdentityRequest {
                role: skir_variant!(ServiceRole::Host {
                    version: "1.0.0".into(),
                }),
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(&identity.body, IssueServiceIdentityResponse::Success(success)
            if success.service_id == "onboarding"),
        "{:?}",
        identity.body
    );

    Seed::new()
        .organization(&acme(), ada())
        .apply(&context.database()?)
        .await?;
    let lease: EnsureRegistrationLeaseResponse = context
        .request(
            "typewriter.from.service.onboarding.registration.ensure",
            &EnsureRegistrationLeaseRequest::default(),
        )
        .await?;
    let EnsureRegistrationLeaseResponse::Issued(lease) = lease else {
        anyhow::bail!("expected an issued registration lease, received {lease:?}");
    };

    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Replace(services)
                if matches!(services.as_slice(), [service]
                    if service.service_id.key.to_string() == "onboarding"
                        && service.organization.as_ref().is_some_and(|organization| organization.key.to_string() == "acme")))
        },
    )?;
    context.expect_publish(
        "typewriter.to.service.onboarding.registration.bound",
        |notification: &ServiceBoundNotification| {
            notification.organization_id == "acme"
                && notification.organization_name.as_deref() == Some("acme")
        },
    )?;
    let binding: BindServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.bind"),
            &BindServiceRequest {
                registration_token: lease.token,
                ..Default::default()
            },
        )
        .await?;
    assert!(
        matches!(&binding, BindServiceResponse::Success(service) if service.service_id == "onboarding"),
        "{binding:?}"
    );
    context.messaging()?.wait_idle().await?;
    assert_jm!(
        context
            .database()?
            .query_json("SELECT VALUE organization FROM ONLY service:onboarding")
            .await?,
        "organization:acme"
    );
    Ok(())
}
