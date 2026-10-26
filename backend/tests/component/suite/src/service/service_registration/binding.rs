use std::time::Duration;

use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::service::v1::{
    organization::OrganizationServicesChanged,
    registration::{
        BindServiceRequest, BindServiceResponse, ServiceBoundNotification, UnbindServiceRequest,
        UnbindServiceResponse,
    },
    service::ServiceRole,
    topology::OrganizationTopologyChanged,
};

use super::{
    Context, ServiceRegistration, acme_with_service, arrange_configuration, globex, paper,
    realm_with_engine, register_host, to_service,
};

const TOKEN: &str = "ABCDEFGHIJ";
const LEASE: Duration = Duration::from_secs(60);

async fn bind(
    context: &Context,
    organization: &Organization,
    token: &str,
) -> anyhow::Result<BindServiceResponse> {
    context
        .request(
            from_member(ada(), organization, "services.bind"),
            &BindServiceRequest {
                registration_token: token.into(),
                ..Default::default()
            },
        )
        .await
}

async fn unbind(context: &Context, key: &str) -> anyhow::Result<UnbindServiceResponse> {
    context
        .request(
            from_member(ada(), &acme(), "services.unbind"),
            &UnbindServiceRequest {
                service_id: key.into(),
                ..Default::default()
            },
        )
        .await
}

/// The organization and lease the service `key` holds.
async fn binding_of(context: &Context, key: &str) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .seed("SELECT VALUE { organization: organization ?? null, token: registration.token ?? null } FROM ONLY $service")
        .bind("service", surrealdb_types::RecordId::new("service", key))?
        .query_json()
        .await
}

#[component_test(ServiceRegistration)]
async fn invalid_registration_token_does_not_bind_service(context: &mut Context) -> TestResult {
    Seed::new()
        .organization(&acme(), ada())
        .service("lobby")
        .registration_lease("lobby", TOKEN, LEASE)
        .apply(&context.database()?)
        .await?;

    let reply = bind(context, &acme(), "ZZZZZZZZZZ").await?;

    assert!(
        matches!(reply, BindServiceResponse::InvalidRegistrationTokenError(_)),
        "{reply:?}"
    );
    assert_jm!(binding_of(context, "lobby").await?, { "organization": null, "token": TOKEN });
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn missing_organization_does_not_consume_registration(context: &mut Context) -> TestResult {
    Seed::new()
        .service("lobby")
        .registration_lease("lobby", TOKEN, LEASE)
        .apply(&context.database()?)
        .await?;

    let reply = bind(context, &Organization::new("missing"), TOKEN).await?;

    assert!(
        matches!(reply, BindServiceResponse::OrganizationNotFoundError(_)),
        "{reply:?}"
    );
    assert_jm!(binding_of(context, "lobby").await?, { "organization": null, "token": TOKEN });
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn valid_registration_binds_service_and_publishes_both_views(
    context: &mut Context,
) -> TestResult {
    acme_with_service(context, "arena").await?;
    Seed::new()
        .service("lobby")
        .registration_lease("lobby", TOKEN, LEASE)
        .apply(&context.database()?)
        .await?;
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

    let reply = bind(context, &acme(), TOKEN).await?;

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
        binding_of(context, "lobby").await?,
        { "organization": "organization:acme", "token": null }
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbind_removes_service_and_topology_from_organization_views(
    context: &mut Context,
) -> TestResult {
    acme_with_service(context, "lobby").await?;
    register_host(context, "lobby", &["paper"]).await?;
    let configured = arrange_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
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

    let reply = unbind(context, "lobby").await?;

    assert!(
        matches!(reply, UnbindServiceResponse::Success(_)),
        "{reply:?}"
    );
    assert_jm!(binding_of(context, "lobby").await?, { "organization": null, "token": null });
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
            .seed("RETURN [record::exists(service_host:lobby), record::exists($realm), record::exists($engine)]")
            .bind("realm", surrealdb_types::RecordId::from(realm.realm_id.clone()))?
            .bind("engine", surrealdb_types::RecordId::from(engine.engine_id.clone()))?
            .query_json()
            .await?,
        [true, true, true]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn unbinding_another_organizations_service_is_not_found(context: &mut Context) -> TestResult {
    Seed::new()
        .organization(&acme(), ada())
        .organization(&globex(), grace())
        .organization_service(&globex(), "lobby")
        .apply(&context.database()?)
        .await?;
    context.expect_no_publish("typewriter.to.organization.*.services.watch")?;
    context.expect_no_publish("typewriter.to.organization.*.topology.watch")?;

    let reply = unbind(context, "lobby").await?;

    assert!(
        matches!(reply, UnbindServiceResponse::ServiceNotFoundError(_)),
        "{reply:?}"
    );
    assert_jm!(
        binding_of(context, "lobby").await?,
        { "organization": "organization:globex", "token": null }
    );
    Ok(())
}
