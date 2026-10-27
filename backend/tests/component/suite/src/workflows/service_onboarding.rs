use json_matcher::assert_jm;
use typewriter_component_test::{
    identity::{Authentik, expect_account_creation, host_role, issue_identity},
    prelude::*,
};
use wasmcloud_utils::{
    skir::base::service::v1::{
        identity::IssueServiceIdentityResponse,
        organization::OrganizationServicesChanged,
        registration::{BindServiceRequest, BindServiceResponse, ServiceBoundNotification},
        status::{EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse},
    },
    transport_routes::service_registration,
};

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
    expect_account_creation(context, "onboarding", 42)?;
    let identity = issue_identity(context, host_role()).await?;
    assert!(
        matches!(&identity.body, IssueServiceIdentityResponse::Success(success)
            if success.service_id == "onboarding"),
        "{:?}",
        identity.body
    );

    seed_organization(context, &acme(), ada(), &[]).await?;
    let lease: EnsureRegistrationLeaseResponse = context
        .request(
            from_service("onboarding", "registration.ensure"),
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
        to_service("onboarding", "registration.bound"),
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
