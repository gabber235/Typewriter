use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{expect_status_update, seed_organization_services},
};
use wasmcloud_utils::skir::base::service::v1::{
    lifecycle::{ServiceHeartbeatNotification, ServiceShutdownNotification},
    service::ServiceStatus,
};

use super::ServiceRegistration;

#[component_test(ServiceRegistration)]
async fn heartbeat_marks_unbound_service_online_without_organization_event(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    Seed::new().service("lobby").apply(context).await?;
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
async fn heartbeat_publishes_bound_service_state(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
    expect_status_update(context, &acme(), "lobby", ServiceStatus::Online)?;

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
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let database = context.database()?;
    Seed::new()
        .organization(&acme(), ada())
        .organization_service(&acme(), "lobby")
        .service_online("lobby")
        .apply(context)
        .await?;
    expect_status_update(context, &acme(), "lobby", ServiceStatus::Offline)?;

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
