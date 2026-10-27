use std::time::Duration;

use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{
        arrange_host_configuration, paper, realm_with_engine, register_host,
        seed_organization_services, seed_registration_lease, unbind_service,
    },
};
use wasmcloud_utils::skir::base::service::v1::{
    organization::OrganizationServicesChanged,
    registration::{
        BindServiceRequest, BindServiceResponse, ServiceBoundNotification, UnbindServiceResponse,
    },
    service::ServiceRole,
    topology::OrganizationTopologyChanged,
};

use super::ServiceRegistration;

/// The registration token of the unbound service `lobby`.
const TOKEN: &str = "ABCDEFGHIJ";
/// How long `lobby`'s registration lease has left.
const LEASE: Duration = Duration::from_secs(60);
/// The organization `lobby` belongs to and the registration token it still holds.
const BINDING: &str = "SELECT VALUE { organization: organization ?? null, token: registration.token ?? null } FROM ONLY service:lobby";

#[component_test(ServiceRegistration)]
async fn invalid_registration_token_does_not_bind_service(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    Seed::new()
        .organization(&acme(), ada())
        .service("lobby")
        .registration_lease("lobby", TOKEN, LEASE)
        .apply(context)
        .await?;

    let reply: BindServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.bind"),
            &BindServiceRequest {
                registration_token: "ZZZZZZZZZZ".into(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, BindServiceResponse::InvalidRegistrationTokenError(_)),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(BINDING).await?, { "organization": null, "token": TOKEN });
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn missing_organization_does_not_consume_registration(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_registration_lease(context, "lobby", TOKEN, LEASE).await?;

    let reply: BindServiceResponse = context
        .request(
            from_member(ada(), &Organization::new("missing"), "services.bind"),
            &BindServiceRequest {
                registration_token: TOKEN.into(),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, BindServiceResponse::OrganizationNotFoundError(_)),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(BINDING).await?, { "organization": null, "token": TOKEN });
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn valid_registration_binds_service_and_publishes_both_views(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["arena"]).await?;
    seed_registration_lease(context, "lobby", TOKEN, LEASE).await?;
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            let OrganizationServicesChanged::Replace(services) = event else {
                return false;
            };
            let mut keys = services
                .iter()
                .map(|service| service.service_id.key.to_string())
                .collect::<Vec<_>>();
            keys.sort_unstable();
            keys == ["arena", "lobby"]
                && services.iter().all(|service| {
                    service
                        .organization
                        .as_ref()
                        .is_some_and(|organization| organization.key.to_string() == "acme")
                })
        },
    )?;
    context.expect_publish(
        to_service("lobby", "registration.bound"),
        |notification: &ServiceBoundNotification| {
            notification.organization_id == "acme"
                && notification.organization_name.as_deref() == Some("acme")
        },
    )?;

    let reply: BindServiceResponse = context
        .request(
            from_member(ada(), &acme(), "services.bind"),
            &BindServiceRequest {
                registration_token: TOKEN.into(),
                ..Default::default()
            },
        )
        .await?;

    let BindServiceResponse::Success(bound) = reply else {
        anyhow::bail!("expected the service to bind, received {reply:?}");
    };
    assert_eq!(bound.service_id, "lobby");
    assert_eq!(bound.service_name.as_deref(), Some("lobby"));
    assert!(
        matches!(bound.service_role, ServiceRole::Host(_)),
        "{:?}",
        bound.service_role
    );
    assert_jm!(
        context.database()?.query_json(BINDING).await?,
        { "organization": "organization:acme", "token": null }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbind_removes_service_and_topology_from_organization_views(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    register_host(context, "lobby", &["paper"]).await?;
    let configured =
        arrange_host_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Replace(services) if services.is_empty())
        },
    )?;
    context.expect_publish(
        to_organization(&acme(), "topology.watch"),
        |event: &OrganizationTopologyChanged| {
            matches!(event, OrganizationTopologyChanged::Replace(topology)
                if topology.hosts.is_empty()
                    && topology.realms.is_empty()
                    && topology.engines.is_empty())
        },
    )?;

    let reply = unbind_service(context, "lobby").await?;

    assert!(
        matches!(reply, UnbindServiceResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(context.database()?.query_json(BINDING).await?, { "organization": null, "token": null });
    let realm = configured
        .realm
        .as_ref()
        .expect("the hosted Realm was configured");
    let engine = configured
        .engine
        .as_ref()
        .expect("the engine was configured");
    assert_jm!(
        context
            .database()?
            .read("RETURN [record::exists(service_host:lobby), record::exists($realm), record::exists($engine)]", &[("realm", realm.realm_id.clone()), ("engine", engine.engine_id.clone())])
            .await?,
        [true, true, true]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbinding_another_organizations_service_is_not_found(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization(context, &acme(), ada(), &[]).await?;
    seed_organization_services(context, &globex(), grace(), &["lobby"]).await?;
    context.expect_no_publish("typewriter.to.organization.*.services.watch")?;
    context.expect_no_publish("typewriter.to.organization.*.topology.watch")?;

    let reply = unbind_service(context, "lobby").await?;

    assert!(
        matches!(reply, UnbindServiceResponse::ServiceNotFoundError(_)),
        "{reply:?}"
    );
    assert_jm!(
        context.database()?.query_json(BINDING).await?,
        { "organization": "organization:globex", "token": null }
    );
    Ok(())
}
