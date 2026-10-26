use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::service::v1::{
    lifecycle::{ServiceHeartbeatNotification, ServiceShutdownNotification},
    organization::OrganizationServicesChanged,
    service::ServiceStatus,
};

use super::{Context, ServiceRegistration, from_service};

/// Expects Acme's watchers to learn that the service `key` is now `status`.
fn expect_status_update(context: &Context, key: &'static str, status: ServiceStatus) -> TestResult {
    context.expect_publish(
        to_organization(&acme(), "services.watch"),
        move |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
            if service.service_id.key.to_string() == key
                && service.state.as_ref().is_some_and(|state| {
                    state.status == status && state.last_seen > std::time::SystemTime::UNIX_EPOCH
                }))
        },
    )?;
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn heartbeat_marks_unbound_service_online_without_organization_event(
    context: &mut Context,
) -> TestResult {
    let database = context.database()?;
    Seed::new().service("lobby").apply(&database).await?;
    context.expect_no_publish("typewriter.to.organization.*.services.watch")?;

    context
        .publish(
            from_service("lobby", "heartbeat"),
            &ServiceHeartbeatNotification::default(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    assert_jm!(
        database
            .query_json("SELECT VALUE [state.status, revision] FROM ONLY service:lobby")
            .await?,
        ["online", 1]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn heartbeat_publishes_bound_service_state(context: &mut Context) -> TestResult {
    let database = context.database()?;
    Seed::new()
        .organization(&acme(), ada())
        .organization_service(&acme(), "lobby")
        .apply(&database)
        .await?;
    expect_status_update(context, "lobby", ServiceStatus::Online)?;

    context
        .publish(
            from_service("lobby", "heartbeat"),
            &ServiceHeartbeatNotification::default(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    assert_jm!(
        database
            .query_json("SELECT VALUE [state.status, state.last_seen != NONE, revision] FROM ONLY service:lobby")
            .await?,
        ["online", true, 1]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn shutdown_marks_bound_service_offline_and_publishes_update(
    context: &mut Context,
) -> TestResult {
    let database = context.database()?;
    Seed::new()
        .organization(&acme(), ada())
        .organization_service(&acme(), "lobby")
        .service_online("lobby")
        .apply(&database)
        .await?;
    expect_status_update(context, "lobby", ServiceStatus::Offline)?;

    context
        .publish(
            from_service("lobby", "shutdown"),
            &ServiceShutdownNotification::default(),
        )
        .await?;
    context.messaging()?.wait_idle().await?;

    assert_jm!(
        database
            .query_json("SELECT VALUE state.status FROM ONLY service:lobby")
            .await?,
        "offline"
    );
    Ok(())
}
